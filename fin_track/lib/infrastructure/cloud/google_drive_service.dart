import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/infrastructure/i_cloud_storage.dart';
import '../diagnostics/error_handling.dart';

part 'google_drive_errors.dart';
part 'google_drive_transport.dart';

class GoogleDriveService implements ICloudStorage {
  GoogleDriveService({
    GoogleSignIn? googleSignIn,
    HttpClient? httpClient,
    GoogleDriveAuthClient? authClient,
    Future<String> Function()? accessTokenProvider,
    GoogleDriveTransport? transport,
  }) : _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: const <String>[oauthScope]),
       _authClient = authClient,
       _accessTokenProvider = accessTokenProvider,
       _transport = transport ?? _HttpClientGoogleDriveTransport(httpClient),
       _simulated = false;

  GoogleDriveService.simulated()
    : _googleSignIn = null,
      _authClient = null,
      _accessTokenProvider = null,
      _transport = null,
      _simulated = true;

  static const oauthScope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _filePrefix = 'fintrack-backup-';
  static const _fileExtension = '.ftbackup';
  static const _mimeType = 'application/octet-stream';

  final GoogleSignIn? _googleSignIn;
  final GoogleDriveAuthClient? _authClient;
  final Future<String> Function()? _accessTokenProvider;
  final GoogleDriveTransport? _transport;
  final bool _simulated;
  final List<Uint8List> _simulatedFiles = <Uint8List>[];
  var _simulatedLinked = false;

  @override
  Future<CloudAccount> linkAccount() async {
    if (_simulated) {
      _simulatedLinked = true;
      return CloudAccount(
        email: 'usuario.fintrack@gmail.com',
        linkedAt: DateTime.now(),
      );
    }

    final account = await _auth().signIn();
    if (account == null) {
      throw StateError('Autenticação Google cancelada.');
    }
    return CloudAccount(email: account.email, linkedAt: DateTime.now());
  }

  @override
  Future<void> unlinkAccount() async {
    if (_simulated) {
      _simulatedLinked = false;
      return;
    }
    await _auth().disconnect();
  }

  @override
  Future<bool> verifyToken() async {
    if (_simulated) {
      return _simulatedLinked;
    }

    return fallbackOnFailure(
      () => _auth().hasValidToken(),
      fallback: false,
      diagnosticContext: 'Falha ao validar token do Google Drive',
      report: true,
    );
  }

  @override
  Future<void> upload(List<Uint8List> files) async {
    if (_simulated) {
      if (!_simulatedLinked) {
        throw StateError('Vincule a conta Google antes de iniciar o backup.');
      }
      _simulatedFiles
        ..clear()
        ..addAll(files.map(Uint8List.fromList));
      return;
    }

    final token = await _accessToken();
    final metadata = await _listBackups(token);
    final fileId = metadata.isNotEmpty
        ? metadata.first['id']?.toString()
        : null;

    if (fileId != null && fileId.isNotEmpty && files.isNotEmpty) {
      await _updateUpload(token, fileId, files.first);
      return;
    }

    for (final file in files) {
      await _upload(token, file);
    }
  }

  Future<void> _updateUpload(String token, String id, Uint8List bytes) async {
    final boundary = 'fintrack-${Random.secure().nextInt(1 << 32)}';
    final metadata = jsonEncode(<String, Object?>{'mimeType': _mimeType});
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(
        utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
      )
      ..add(utf8.encode(metadata))
      ..add(utf8.encode('\r\n--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: $_mimeType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final uri = Uri.https(
      'www.googleapis.com',
      '/upload/drive/v3/files/$id',
      <String, String>{
        'uploadType': 'multipart',
        'fields': 'id,name,createdTime',
      },
    );
    final response = await _send(
      'PATCH',
      uri,
      token,
      contentType: 'multipart/related; boundary=$boundary',
      body: body.takeBytes(),
    );
    _validateStatus(response, 'update the backup on Google Drive');
  }

  @override
  Future<void> deleteBackup() async {
    if (_simulated) {
      if (!_simulatedLinked) {
        throw StateError('Vincule a conta Google antes de excluir o backup.');
      }
      _simulatedFiles.clear();
      return;
    }

    final token = await _accessToken();
    final metadata = await _listAppDataFiles(token);
    if (metadata.isEmpty) {
      return;
    }

    for (final item in metadata) {
      final fileId = item['id']?.toString();
      if (fileId == null || fileId.isEmpty) {
        continue;
      }
      await _deleteBackup(token, fileId);
    }
  }

  Future<List<Map<String, dynamic>>> _listAppDataFiles(String token) {
    return _listFiles(
      token,
      description: 'list all FinTrack data on Google Drive',
    );
  }

  Future<void> _deleteBackup(String token, String id) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/$id');
    final response = await _send('DELETE', uri, token);
    if (response.statusCode == HttpStatus.noContent) {
      return;
    }
    _validateStatus(response, 'delete FinTrack data from Google Drive');
  }

  @override
  Future<List<Uint8List>> download() async {
    if (_simulated) {
      if (!_simulatedLinked) {
        throw StateError('Vincule a conta Google antes de restaurar o backup.');
      }
      return _simulatedFiles.map(Uint8List.fromList).toList();
    }

    final token = await _accessToken();
    final metadata = await _listBackups(token);
    final files = <Uint8List>[];
    for (final item in metadata) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      files.add(await _download(token, id));
    }
    return files;
  }

  Future<String> _accessToken() async {
    final provider = _accessTokenProvider;
    if (provider != null) {
      final token = await provider();
      if (token.isEmpty) {
        throw StateError('Sessão Google expirada. Vincule a conta novamente.');
      }
      return token;
    }

    final token = await _auth().accessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sessão Google expirada. Vincule a conta novamente.');
    }
    return token;
  }

  GoogleDriveAuthClient _auth() {
    return _authClient ?? _GoogleSignInAuthClient(_googleSignIn!);
  }

  Future<void> _upload(String token, Uint8List bytes) async {
    final boundary = 'fintrack-${Random.secure().nextInt(1 << 32)}';
    final name =
        '$_filePrefix${DateTime.now().toUtc().toIso8601String()}$_fileExtension';
    final metadata = jsonEncode(<String, Object?>{
      'name': name,
      'parents': <String>['appDataFolder'],
      'mimeType': _mimeType,
    });
    final body = BytesBuilder()
      ..add(utf8.encode('--$boundary\r\n'))
      ..add(
        utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
      )
      ..add(utf8.encode(metadata))
      ..add(utf8.encode('\r\n--$boundary\r\n'))
      ..add(utf8.encode('Content-Type: $_mimeType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));

    final uri = Uri.https(
      'www.googleapis.com',
      '/upload/drive/v3/files',
      <String, String>{
        'uploadType': 'multipart',
        'fields': 'id,name,createdTime',
      },
    );
    final response = await _send(
      'POST',
      uri,
      token,
      contentType: 'multipart/related; boundary=$boundary',
      body: body.takeBytes(),
    );
    _validateStatus(response, 'upload the backup to Google Drive');
  }

  Future<List<Map<String, dynamic>>> _listBackups(String token) async {
    final files = await _listFiles(
      token,
      q: "name contains '$_filePrefix' and trashed = false",
      description: 'list Google Drive backups',
    );
    return files
        .where(
          (item) => item['name']?.toString().endsWith(_fileExtension) ?? false,
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _listFiles(
    String token, {
    String? q,
    required String description,
  }) async {
    final files = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final query = <String, String>{
        'spaces': 'appDataFolder',
        'fields': 'nextPageToken,files(id,name,createdTime,modifiedTime,size)',
        'orderBy': 'createdTime desc',
        'pageSize': '1000',
      };
      if (q != null) {
        query['q'] = q;
      }
      if (pageToken != null) {
        query['pageToken'] = pageToken;
      }
      final uri = Uri.https('www.googleapis.com', '/drive/v3/files', query);
      final response = await _send('GET', uri, token);
      _validateStatus(response, description);
      final decoded = jsonDecode(utf8.decode(response.body));
      final pageFiles = decoded is Map ? decoded['files'] : null;
      if (pageFiles is List) {
        files.addAll(
          pageFiles.whereType<Map>().map(
            (item) => item.cast<String, dynamic>(),
          ),
        );
      }
      pageToken = decoded is Map ? decoded['nextPageToken']?.toString() : null;
    } while (pageToken != null && pageToken.isNotEmpty);
    return files;
  }

  Future<Uint8List> _download(String token, String id) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/$id', {
      'alt': 'media',
    });
    final response = await _send('GET', uri, token);
    _validateStatus(response, 'download the backup from Google Drive');
    return response.body;
  }

  Future<_HttpResponse> _send(
    String method,
    Uri uri,
    String token, {
    String? contentType,
    Uint8List? body,
  }) async {
    return _transport!
        .send(method, uri, token, contentType: contentType, body: body)
        .then((response) => _HttpResponse(response.statusCode, response.body));
  }

  void _validateStatus(_HttpResponse response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final detail = _googleErrorDetail(response);
    throw CloudStorageFailure(
      _userMessage(response.statusCode, detail),
      technicalDetail:
          'HTTP ${response.statusCode} while trying to $action. $detail',
    );
  }
}

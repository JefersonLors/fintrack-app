import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fin_track/domain/infrastructure/i_cloud_storage.dart';
import 'package:fin_track/infrastructure/cloud/google_drive_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drive account keeps the authenticated email', () {
    final account = GoogleDriveAccount('account@test.com');

    expect(account.email, 'account@test.com');
  });

  test(
    'real drive with fake transport sends new backup updates and downloads',
    () async {
      final transport = _DriveTransportFake();
      final service = GoogleDriveService(
        accessTokenProvider: () async => 'test-token',
        transport: transport,
      );

      await service.upload([
        Uint8List.fromList([1, 2, 3]),
      ]);
      expect(transport.calls.map((call) => call.method), ['GET', 'POST']);
      expect(transport.uploads.single, [1, 2, 3]);

      await service.upload([
        Uint8List.fromList([4, 5]),
      ]);
      expect(transport.calls.map((call) => call.method), [
        'GET',
        'POST',
        'GET',
        'PATCH',
      ]);
      expect(transport.updates.single, [4, 5]);

      final files = await service.download();
      expect(files, hasLength(1));
      expect(files.single, [9, 8, 7]);
    },
  );

  test('real drive deletes appData files and ignores empty ids', () async {
    final transport = _DriveTransportFake()
      ..files = [
        {'id': 'backup-1', 'name': 'fintrack-backup-a.ftbackup'},
        {'id': '', 'name': 'ignored.ftbackup'},
        {'name': 'sem-id.ftbackup'},
      ];
    final service = GoogleDriveService(
      accessTokenProvider: () async => 'test-token',
      transport: transport,
    );

    await service.deleteBackup();

    expect(transport.deletedIds, ['backup-1']);
  });

  test('real drive turns Google failures into friendly messages', () async {
    final transport = _DriveTransportFake(
      forcedResponse: GoogleDriveHttpResponse(
        HttpStatus.forbidden,
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'error': {
                'status': 'PERMISSION_DENIED',
                'message': 'Drive API has not been used',
                'errors': [
                  {'reason': 'accessNotConfigured'},
                ],
              },
            }),
          ),
        ),
      ),
    );
    final service = GoogleDriveService(
      accessTokenProvider: () async => 'test-token',
      transport: transport,
    );

    await expectLater(
      service.download(),
      throwsA(
        isA<CloudStorageFailure>()
            .having(
              (error) => error.userMessage,
              'userMessage',
              contains('API do Google Drive'),
            )
            .having(
              (error) => error.technicalDetail,
              'technicalDetail',
              contains('PERMISSION_DENIED'),
            ),
      ),
    );
  });

  test('real drive validates empty injected token', () async {
    final service = GoogleDriveService(
      accessTokenProvider: () async => '',
      transport: _DriveTransportFake(),
    );

    await expectLater(service.download(), throwsA(isA<StateError>()));
  });

  test('real drive uses injected authentication client', () async {
    final auth = _AuthFake(
      account: const GoogleDriveAccount('account@test.com'),
    );
    final service = GoogleDriveService(
      authClient: auth,
      transport: _DriveTransportFake(),
    );

    final account = await service.linkAccount();
    expect(account.email, 'account@test.com');
    expect(await service.verifyToken(), isTrue);
    await service.download();
    await service.unlinkAccount();

    expect(auth.signInCalls, 1);
    expect(auth.tokenCalls, 1);
    expect(auth.disconnectCalls, 1);
  });

  test(
    'real drive handles cancellation missing token and token verification error',
    () async {
      final cancelled = GoogleDriveService(
        authClient: _AuthFake(),
        transport: _DriveTransportFake(),
      );
      await expectLater(cancelled.linkAccount(), throwsA(isA<StateError>()));

      final withoutToken = GoogleDriveService(
        authClient: _AuthFake(
          account: const GoogleDriveAccount('account@test.com'),
          token: null,
        ),
        transport: _DriveTransportFake(),
      );
      await expectLater(withoutToken.download(), throwsA(isA<StateError>()));

      final tokenFailure = GoogleDriveService(
        authClient: _AuthFake(
          account: const GoogleDriveAccount('account@test.com'),
          hasValidTokenError: StateError('falhou'),
        ),
        transport: _DriveTransportFake(),
      );
      expect(await tokenFailure.verifyToken(), isFalse);
    },
  );

  test(
    'real drive maps common HTTP statuses and details without JSON',
    () async {
      await _expectGoogleFailure(
        GoogleDriveHttpResponse(HttpStatus.unauthorized, Uint8List(0)),
        contains('sessão Google expirou'),
        detail: contains('Resposta vazia'),
      );
      await _expectGoogleFailure(
        GoogleDriveHttpResponse(
          HttpStatus.forbidden,
          Uint8List.fromList(utf8.encode('insufficient scope')),
        ),
        contains('não autorizou'),
      );
      await _expectGoogleFailure(
        GoogleDriveHttpResponse(
          HttpStatus.notFound,
          Uint8List.fromList(utf8.encode('plain not found')),
        ),
        contains('não foi encontrado'),
      );
      await _expectGoogleFailure(
        GoogleDriveHttpResponse(
          HttpStatus.tooManyRequests,
          Uint8List.fromList(utf8.encode('rate limit')),
        ),
        contains('temporariamente indisponível'),
      );
      await _expectGoogleFailure(
        GoogleDriveHttpResponse(
          HttpStatus.badRequest,
          Uint8List.fromList(utf8.encode(List.filled(600, 'x').join())),
        ),
        contains('Não foi possível comunicar'),
        detail: predicate<String?>(
          (detail) => detail != null && detail.length < 590,
        ),
      );
    },
  );
}

Future<void> _expectGoogleFailure(
  GoogleDriveHttpResponse response,
  Matcher message, {
  Matcher? detail,
}) async {
  final service = GoogleDriveService(
    accessTokenProvider: () async => 'test-token',
    transport: _DriveTransportFake(forcedResponse: response),
  );

  await expectLater(
    service.download(),
    throwsA(
      isA<CloudStorageFailure>()
          .having((error) => error.userMessage, 'userMessage', message)
          .having(
            (error) => error.technicalDetail,
            'technicalDetail',
            detail ?? anything,
          ),
    ),
  );
}

class _DriveTransportFake implements GoogleDriveTransport {
  _DriveTransportFake({this.forcedResponse});

  final GoogleDriveHttpResponse? forcedResponse;
  final calls = <_DriveCall>[];
  final uploads = <List<int>>[];
  final updates = <List<int>>[];
  final deletedIds = <String>[];
  var files = <Map<String, Object?>>[];

  @override
  Future<GoogleDriveHttpResponse> send(
    String method,
    Uri uri,
    String token, {
    String? contentType,
    Uint8List? body,
  }) async {
    calls.add(_DriveCall(method, uri));
    final forced = forcedResponse;
    if (forced != null) {
      return forced;
    }

    if (method == 'GET' && uri.path == '/drive/v3/files') {
      return _json({'files': files, 'nextPageToken': ''});
    }
    if (method == 'POST' && uri.path == '/upload/drive/v3/files') {
      uploads.add(_extractMultipartPayload(body));
      files = [
        {'id': 'backup-1', 'name': 'fintrack-backup-a.ftbackup'},
      ];
      return _json({'id': 'backup-1'});
    }
    if (method == 'PATCH' && uri.path == '/upload/drive/v3/files/backup-1') {
      updates.add(_extractMultipartPayload(body));
      return _json({'id': 'backup-1'});
    }
    if (method == 'GET' && uri.path == '/drive/v3/files/backup-1') {
      return GoogleDriveHttpResponse(
        HttpStatus.ok,
        Uint8List.fromList([9, 8, 7]),
      );
    }
    if (method == 'DELETE' && uri.path == '/drive/v3/files/backup-1') {
      deletedIds.add('backup-1');
      return GoogleDriveHttpResponse(HttpStatus.noContent, Uint8List(0));
    }

    return GoogleDriveHttpResponse(HttpStatus.notFound, Uint8List(0));
  }

  GoogleDriveHttpResponse _json(Map<String, Object?> payload) {
    return GoogleDriveHttpResponse(
      HttpStatus.ok,
      Uint8List.fromList(utf8.encode(jsonEncode(payload))),
    );
  }

  List<int> _extractMultipartPayload(Uint8List? body) {
    final bytes = body ?? Uint8List(0);
    final marker = utf8.encode(
      'Content-Type: application/octet-stream\r\n\r\n',
    );
    for (var index = 0; index <= bytes.length - marker.length; index++) {
      var matches = true;
      for (var markerIndex = 0; markerIndex < marker.length; markerIndex++) {
        if (bytes[index + markerIndex] != marker[markerIndex]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        final start = index + marker.length;
        final end = bytes.indexOf(13, start);
        return bytes.sublist(start, end == -1 ? bytes.length : end);
      }
    }
    return bytes;
  }
}

class _AuthFake implements GoogleDriveAuthClient {
  _AuthFake({this.account, this.token = 'test-token', this.hasValidTokenError});

  final GoogleDriveAccount? account;
  final String? token;
  final Object? hasValidTokenError;
  var signInCalls = 0;
  var disconnectCalls = 0;
  var tokenCalls = 0;

  @override
  Future<GoogleDriveAccount?> signIn() async {
    signInCalls++;
    return account;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<bool> hasValidToken() async {
    final error = hasValidTokenError;
    if (error != null) {
      throw error;
    }
    return token != null;
  }

  @override
  Future<String?> accessToken() async {
    tokenCalls++;
    return token;
  }
}

class _DriveCall {
  const _DriveCall(this.method, this.uri);

  final String method;
  final Uri uri;
}

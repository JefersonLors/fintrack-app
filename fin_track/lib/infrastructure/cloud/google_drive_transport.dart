part of 'google_drive_service.dart';

class _HttpResponse {
  const _HttpResponse(this.statusCode, this.body);

  final int statusCode;
  final Uint8List body;
}

abstract class GoogleDriveTransport {
  Future<GoogleDriveHttpResponse> send(
    String method,
    Uri uri,
    String token, {
    String? contentType,
    Uint8List? body,
  });
}

class GoogleDriveHttpResponse {
  const GoogleDriveHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final Uint8List body;
}

// Thin adapter for the real HttpClient. Drive logic is tested with a fake
// GoogleDriveTransport in google_drive_service_http_test.dart.
// coverage:ignore-start
class _HttpClientGoogleDriveTransport implements GoogleDriveTransport {
  _HttpClientGoogleDriveTransport(this._httpClient);

  final HttpClient? _httpClient;

  @override
  Future<GoogleDriveHttpResponse> send(
    String method,
    Uri uri,
    String token, {
    String? contentType,
    Uint8List? body,
  }) async {
    final client = _httpClient ?? HttpClient();
    final request = await client.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    if (contentType != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    }
    if (body != null) {
      request.contentLength = body.length;
      request.add(body);
    }
    final response = await request.close();
    final builder = BytesBuilder();
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (_httpClient == null) {
      client.close();
    }
    return GoogleDriveHttpResponse(response.statusCode, bytes);
  }
}
// coverage:ignore-end

class GoogleDriveAccount {
  const GoogleDriveAccount(this.email);

  final String email;
}

abstract class GoogleDriveAuthClient {
  Future<GoogleDriveAccount?> signIn();
  Future<void> disconnect();
  Future<bool> hasValidToken();
  Future<String?> accessToken();
}

// Thin adapter for the GoogleSignIn plugin. Authentication logic is tested with
// a fake GoogleDriveAuthClient in google_drive_service_http_test.dart.
// coverage:ignore-start
class _GoogleSignInAuthClient implements GoogleDriveAuthClient {
  _GoogleSignInAuthClient(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleDriveAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }
    await account.authentication;
    return GoogleDriveAccount(account.email);
  }

  @override
  Future<void> disconnect() {
    return _googleSignIn.disconnect();
  }

  @override
  Future<bool> hasValidToken() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      return false;
    }
    final auth = await account.authentication;
    return auth.accessToken != null;
  }

  @override
  Future<String?> accessToken() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw StateError('Vincule a conta Google antes de continuar.');
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }
}

// coverage:ignore-end

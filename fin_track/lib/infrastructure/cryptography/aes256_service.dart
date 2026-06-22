import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../domain/infrastructure/i_cryptography_service.dart';

class AES256Service implements ICryptographyService {
  AES256Service({Random? random, int iterations = _defaultIterations})
    : _random = random ?? Random.secure(),
      _iterations = iterations;

  static const _magic = 'FTBACKUP';
  static const _version = 2;
  static const _kdfAlgorithm = 'pbkdf2-hmac-sha256';
  static const _cipherAlgorithm = 'aes-gcm-256';
  static const _defaultIterations = 310000;
  static const _saltLength = 32;

  final Random _random;
  final int _iterations;

  @override
  Future<Uint8List> encrypt(Uint8List data, String password) async {
    final salt = _randomBytes(_saltLength);
    final algorithm = AesGcm.with256bits();
    final nonce = _randomBytes(algorithm.nonceLength);
    final secretKey = await _deriveKey(password: password, salt: salt);
    final secretBox = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = <String, Object?>{
      'magic': _magic,
      'version': _version,
      'kdf': <String, Object?>{
        'algorithm': _kdfAlgorithm,
        'iterations': _iterations,
        'saltBase64': base64Encode(salt),
      },
      'cipher': <String, Object?>{
        'algorithm': _cipherAlgorithm,
        'nonceBase64': base64Encode(secretBox.nonce),
        'macBase64': base64Encode(secretBox.mac.bytes),
      },
      'ciphertextBase64': base64Encode(secretBox.cipherText),
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  @override
  Future<Uint8List> decrypt(Uint8List encryptedData, String password) async {
    try {
      final envelope = _decodeEnvelope(encryptedData);
      final kdf = _map(envelope['kdf']);
      final cipher = _map(envelope['cipher']);

      _validateEnvelope(envelope, kdf, cipher);

      final salt = base64Decode(_string(kdf['saltBase64']));
      final nonce = base64Decode(_string(cipher['nonceBase64']));
      final mac = Mac(base64Decode(_string(cipher['macBase64'])));
      final cipherText = base64Decode(_string(envelope['ciphertextBase64']));

      final secretKey = await _deriveKey(
        password: password,
        salt: salt,
        iterations: _int(kdf['iterations']),
      );
      final opened = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: secretKey,
      );
      return Uint8List.fromList(opened);
    } catch (error, stackTrace) {
      final sanitizedError = error is FormatException
          ? error
          : const FormatException('Senha incorreta ou backup corrompido.');
      Error.throwWithStackTrace(sanitizedError, stackTrace);
    }
  }

  Future<SecretKey> _deriveKey({
    required String password,
    required List<int> salt,
    int? iterations,
  }) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations ?? _iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  Map<String, Object?> _decodeEnvelope(Uint8List encryptedData) {
    final decoded = jsonDecode(utf8.decode(encryptedData));
    if (decoded is! Map) {
      throw const FormatException('Envelope de backup inválido.');
    }
    return Map<String, Object?>.from(decoded);
  }

  void _validateEnvelope(
    Map<String, Object?> envelope,
    Map<String, Object?> kdf,
    Map<String, Object?> cipher,
  ) {
    if (envelope['magic'] != _magic ||
        envelope['version'] != _version ||
        kdf['algorithm'] != _kdfAlgorithm ||
        cipher['algorithm'] != _cipherAlgorithm) {
      throw const FormatException('Formato de backup não suportado.');
    }
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw const FormatException('Metadados de backup inválidos.');
  }

  String _string(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      throw const FormatException('Metadados de backup incompletos.');
    }
    return text;
  }

  int _int(Object? value) {
    if (value is int) {
      return value;
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      throw const FormatException('Parâmetros de derivação inválidos.');
    }
    return parsed;
  }
}

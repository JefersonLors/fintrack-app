import 'dart:typed_data';

abstract class ICryptographyService {
  Future<Uint8List> encrypt(Uint8List data, String password);
  Future<Uint8List> decrypt(Uint8List encryptedData, String password);
}

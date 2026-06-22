import 'package:fin_track/infrastructure/security/fin_track_local_authentication_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fin_track/native');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('local authentication service delegates PIN removal', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'removeLocalPin' => true,
        _ => null,
      };
    });

    const service = FinTrackLocalAuthenticationService();

    expect(await service.removePin(), isTrue);
    expect(calls, ['removeLocalPin']);
  });
}

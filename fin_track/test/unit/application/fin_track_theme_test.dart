import 'dart:typed_data';

import 'package:fin_track/domain/infrastructure/i_cloud_storage.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applies tokens when light and dark themes are created', () {
    GoogleFonts.config.allowRuntimeFetching = false;

    final custom = FinTrackColorScheme.dark.copyWith(
      background: Colors.black,
      surface: Colors.white,
      surfaceAlt: Colors.red,
      border: Colors.green,
      borderStrong: Colors.blue,
      primary: Colors.yellow,
      income: Colors.pink,
      expense: Colors.orange,
      receiptType: Colors.purple,
      paymentMethod: Colors.cyan,
      backup: Colors.teal,
      info: Colors.indigo,
      danger: Colors.brown,
      neutralAccent: Colors.grey,
      textPrimary: Colors.lime,
      textSecondary: Colors.amber,
      textMuted: Colors.blueGrey,
    );

    expect(custom.background, Colors.black);
    final defaultScheme = FinTrackColorScheme.dark.copyWith();
    expect(defaultScheme.background, FinTrackColorScheme.dark.background);
    expect(defaultScheme.surface, FinTrackColorScheme.dark.surface);
    expect(defaultScheme.surfaceAlt, FinTrackColorScheme.dark.surfaceAlt);
    expect(defaultScheme.border, FinTrackColorScheme.dark.border);
    expect(defaultScheme.borderStrong, FinTrackColorScheme.dark.borderStrong);
    expect(defaultScheme.primary, FinTrackColorScheme.dark.primary);
    expect(defaultScheme.income, FinTrackColorScheme.dark.income);
    expect(defaultScheme.expense, FinTrackColorScheme.dark.expense);
    expect(defaultScheme.receiptType, FinTrackColorScheme.dark.receiptType);
    expect(defaultScheme.paymentMethod, FinTrackColorScheme.dark.paymentMethod);
    expect(defaultScheme.backup, FinTrackColorScheme.dark.backup);
    expect(defaultScheme.info, FinTrackColorScheme.dark.info);
    expect(defaultScheme.danger, FinTrackColorScheme.dark.danger);
    expect(defaultScheme.neutralAccent, FinTrackColorScheme.dark.neutralAccent);
    expect(defaultScheme.textPrimary, FinTrackColorScheme.dark.textPrimary);
    expect(defaultScheme.textSecondary, FinTrackColorScheme.dark.textSecondary);
    expect(defaultScheme.textMuted, FinTrackColorScheme.dark.textMuted);
    expect(FinTrackColorScheme.dark.lerp(null, 0.5), FinTrackColorScheme.dark);

    final lerped = FinTrackColorScheme.dark.lerp(
      FinTrackColorScheme.light,
      0.5,
    );
    expect(
      lerped.primary,
      Color.lerp(
        FinTrackColorScheme.dark.primary,
        FinTrackColorScheme.light.primary,
        0.5,
      ),
    );

    final dark = FinTrackTheme.dark();
    final light = FinTrackTheme.light();
    expect(dark.extension<FinTrackColorScheme>(), FinTrackColorScheme.dark);
    expect(light.extension<FinTrackColorScheme>(), FinTrackColorScheme.light);

    final darkLabel = dark.navigationBarTheme.labelTextStyle!.resolve({
      WidgetState.selected,
    });
    final darkIcon = dark.navigationBarTheme.iconTheme!.resolve({
      WidgetState.selected,
    });
    final lightLabel = light.navigationBarTheme.labelTextStyle!.resolve({});
    final lightIcon = light.navigationBarTheme.iconTheme!.resolve({});
    final lightSelectedLabel = light.navigationBarTheme.labelTextStyle!.resolve(
      {WidgetState.selected},
    );
    final lightSelectedIcon = light.navigationBarTheme.iconTheme!.resolve({
      WidgetState.selected,
    });

    expect(darkLabel?.fontWeight, FontWeight.w700);
    expect(darkIcon?.color, FinTrackColors.primary);
    expect(lightLabel?.fontWeight, FontWeight.w500);
    expect(lightIcon?.color, FinTrackColorScheme.light.textMuted);
    expect(lightSelectedLabel?.fontWeight, FontWeight.w700);
    expect(lightSelectedIcon?.color, FinTrackColorScheme.light.primary);
  });

  testWidgets('uses fallback when theme extension does not exist', (
    tester,
  ) async {
    late FinTrackColorScheme colors;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            colors = context.finTrackColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(colors, FinTrackColorScheme.dark);
  });

  test('runs contracts when cloud storage changes state', () async {
    final account = CloudAccount(
      email: 'account@fintrack.test',
      linkedAt: DateTime(2026, 5, 23),
    );
    expect(account.email, 'account@fintrack.test');

    expect(const CloudStorageFailure('Falha').toString(), 'Falha');
    expect(
      const CloudStorageFailure(
        'Falha',
        technicalDetail: 'HTTP 500',
      ).toString(),
      'Falha (HTTP 500)',
    );

    final storage = _FakeCloudStorage(account);
    expect(await storage.linkAccount(), account);
    expect(await storage.verifyToken(), isTrue);
    await storage.upload([
      Uint8List.fromList([1, 2, 3]),
    ]);
    expect(await storage.download(), hasLength(1));
    await storage.deleteBackup();
    expect(await storage.download(), isEmpty);
    await storage.unlinkAccount();
    expect(await storage.verifyToken(), isFalse);
  });
}

class _FakeCloudStorage implements ICloudStorage {
  _FakeCloudStorage(this._account);

  final CloudAccount _account;
  final _files = <Uint8List>[];
  var _linked = false;

  @override
  Future<CloudAccount> linkAccount() async {
    _linked = true;
    return _account;
  }

  @override
  Future<void> unlinkAccount() async {
    _linked = false;
  }

  @override
  Future<bool> verifyToken() async => _linked;

  @override
  Future<void> upload(List<Uint8List> files) async {
    _files
      ..clear()
      ..addAll(files);
  }

  @override
  Future<List<Uint8List>> download() async => List.of(_files);

  @override
  Future<void> deleteBackup() async {
    _files.clear();
  }
}

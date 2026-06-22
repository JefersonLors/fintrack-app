import 'package:fin_track/application/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppConfig applies flexible parsing', () {
    final config = AppConfig.fromJson({
      'version': '2',
      'debugMode': 'true',
      'app': {'displayName': 'FinTrack Teste'},
      'support': {'email': 'suporte@teste.dev'},
      'about': {
        'features': ['OCR', ' '],
        'faq': [
          {'question': 'Q', 'answer': 'A'},
        ],
      },
      'onboarding': {
        'slides': [
          {'icon': 'scan', 'title': 'Digitalize', 'body': 'Capture'},
        ],
      },
      'ui': {
        'common': {'cancel': 'Voltar'},
        'backup': {'backupCompleted': 'Backup finalizado.'},
        'receiptDetail': {'title': 'Comprovante'},
        'receipts': {
          'files': {'fileSaved': 'Arquivo guardado.'},
          'filesSaveFailed': 'Falha ao guardar arquivos.',
        },
      },
    });

    expect(config.version, 2);
    expect(config.debugMode, isTrue);
    expect(config.app.displayName, 'FinTrack Teste');
    expect(config.app.logoAsset, AppConfig.defaults.app.logoAsset);
    expect(config.support.email, 'suporte@teste.dev');
    expect(config.about.features, ['OCR']);
    expect(config.about.faq.single.question, 'Q');
    expect(config.onboarding.slides.single.icon, 'scan');
    expect(config.ui.common.cancel, 'Voltar');
    expect(config.ui.common.save, AppConfig.defaults.ui.common.save);
    expect(config.ui.backup.backupCompleted, 'Backup finalizado.');
    expect(config.ui.receiptDetail.title, 'Comprovante');
    expect(config.ui.receipts.files.fileSaved, 'Arquivo guardado.');
    expect(
      config.ui.receipts.files.filesSaveFailed,
      'Falha ao guardar arquivos.',
    );
  });

  test('AppConfig uses defaults for invalid asset and empty values', () async {
    final config = AppConfig.fromJson({
      'version': 'x',
      'debugMode': 'false',
      'about': {
        'features': <Object?>[],
        'faq': <Object?>['x'],
      },
      'onboarding': {
        'slides': <Object?>['x'],
      },
    });

    expect(config.version, AppConfig.defaults.version);
    expect(config.debugMode, isFalse);
    expect(config.about.features, AppConfig.defaults.about.features);
    expect(config.about.faq, AppConfig.defaults.about.faq);
    expect(config.onboarding.slides, AppConfig.defaults.onboarding.slides);
    expect(
      await AppConfig.loadFromAsset(path: 'invalid.json'),
      AppConfig.defaults,
    );
  });
}

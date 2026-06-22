import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/presentation/backup/widgets/backup_password_dialog.dart';
import 'package:fin_track/presentation/configuration/widgets/configuration_dialogs.dart';
import 'package:fin_track/presentation/receipts/widgets/receipt_list_filter_sheet.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('backup password dialog validates confirmation and cancel', (
    tester,
  ) async {
    Object? result = 'pending';
    await tester.pumpWidget(
      _Host(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: context,
                builder: (_) => const BackupPasswordDialog(
                  confirmation: true,
                  title: 'Título customizado',
                  message: 'Mensagem customizada',
                  actionLabel: 'Confirmar',
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Título customizado'), findsOneWidget);
    expect(find.text('Mensagem customizada'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      '12345678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar senha'),
      '87654321',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pump();
    expect(find.text('As senhas não conferem.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('configuration dialogs return selected actions', (tester) async {
    await tester.pumpWidget(
      _Host(
        child: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () =>
                    showAutomaticBackupPasswordRequiredDialog(context),
                child: const Text('Senha'),
              ),
              FilledButton(
                onPressed: () async {
                  final exit = await confirmApplicationExit(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('exit=$exit')));
                  }
                },
                child: const Text('Sair'),
              ),
              FilledButton(
                onPressed: () async {
                  final method = await selectAuthenticationMethodDialog(
                    context,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(method?.persistedValue ?? '-')),
                    );
                  }
                },
                child: const Text('Proteção'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair').last);
    await tester.pumpAndSettle();
    expect(find.text('exit=true'), findsOneWidget);

    await tester.tap(find.text('Proteção'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biometria'));
    await tester.pumpAndSettle();
  });

  testWidgets('receipt filter sheet applies category type nature and clears', (
    tester,
  ) async {
    final results = <ReceiptListFilterSelection?>[];
    await tester.pumpWidget(
      _Host(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              results.add(
                await showReceiptListFilterSheet(
                  context,
                  categories: const [Category(id: 7, name: 'Casa')],
                  categoryId: null,
                  withoutCategory: false,
                  type: null,
                  expense: null,
                  startDate: null,
                  endDate: null,
                ),
              );
            },
            child: const Text('Filtros'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReceiptType.invoice.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receitas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
    await tester.pumpAndSettle();

    expect(results.single?.categoryId, 7);
    expect(results.single?.type, ReceiptType.invoice);
    expect(results.single?.expense, isFalse);
    expect(results.single?.activeLabel, contains('Casa'));

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Limpar'),
      300,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Limpar'));
    await tester.pumpAndSettle();
    expect(results.last?.activeLabel, isNull);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ScopedHost(child: child);
  }
}

class _ScopedHost extends StatefulWidget {
  const _ScopedHost({required this.child});

  final Widget child;

  @override
  State<_ScopedHost> createState() => _ScopedHostState();
}

class _ScopedHostState extends State<_ScopedHost> {
  late final FinTrackDependencies _dependencies = FinTrackDependencies.local();

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: _dependencies,
      child: MaterialApp(
        theme: FinTrackTheme.light(),
        home: Scaffold(body: widget.child),
      ),
    );
  }
}

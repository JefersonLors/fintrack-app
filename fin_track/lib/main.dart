import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'application/backup/background_backup_entrypoint.dart';
import 'application/receipts/batch/background_receipt_batch_entrypoint.dart';
import 'application/receipts/semantic/background_semantic_index_entrypoint.dart';
import 'application/policies/backup_automatic_policy.dart';
import 'bootstrap/fin_track_dependencies.dart';
import 'domain/entities/configuration.dart';
import 'infrastructure/diagnostics/fin_track_error_log.dart';
import 'infrastructure/image/fin_track_platform.dart';
import 'presentation/authentication/authentication_gate.dart';
import 'presentation/camera/processing_page.dart';
import 'presentation/receipts/pages/receipt_batch_processing_page.dart';
import 'presentation/shell/fin_track_shell.dart';
import 'presentation/theme/fin_track_theme.dart';
import 'presentation/widgets/app_scope.dart';
import 'presentation/widgets/blocking_progress_dialog.dart';
import 'presentation/widgets/storage_limit_feedback.dart';

// coverage:ignore-start
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final originalFlutterErrorHandler = FlutterError.onError;
  final originalPlatformErrorHandler = PlatformDispatcher.instance.onError;
  FlutterError.onError = (details) {
    FinTrackErrorLog.record(details.exception, details.stack);
    if (originalFlutterErrorHandler != null) {
      originalFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FinTrackErrorLog.record(error, stack);
    return originalPlatformErrorHandler?.call(error, stack) ?? false;
  };

  await _loadInitialFonts();
  final dependencies = await FinTrackDependencies.persistent();
  final initialConfiguration = await loadInitialConfiguration(dependencies);
  runApp(
    FinTrackApp(
      dependencies: dependencies,
      initialConfiguration: initialConfiguration,
    ),
  );
}
// coverage:ignore-end

Future<void> _loadInitialFonts() async {
  if (!GoogleFonts.config.allowRuntimeFetching) {
    return;
  }
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.manropeTextTheme(ThemeData(useMaterial3: true).textTheme),
    ]);
  } catch (error, stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
  }
}

@pragma('vm:entry-point')
Future<void> finTrackBackgroundBackupDispatcher() {
  return runFinTrackBackgroundBackup();
}

@pragma('vm:entry-point')
Future<void> finTrackBackgroundReceiptBatchDispatcher() {
  return runFinTrackBackgroundReceiptBatchImport();
}

@pragma('vm:entry-point')
Future<void> finTrackBackgroundSemanticIndexDispatcher() {
  return runFinTrackBackgroundSemanticIndex();
}

Future<Configuration> loadInitialConfiguration(
  FinTrackDependencies dependencies,
) async {
  try {
    await dependencies.configurationService.normalizeAutomaticBackupIfNeeded();
    return await dependencies.configurationService.load();
  } catch (error, stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
    return const Configuration(id: 1);
  }
}

typedef SharedFilePageBuilder =
    Widget Function(
      BuildContext context,
      File file,
      Future<void> Function() onFinished,
    );

typedef SharedFileBatchPageBuilder =
    Widget Function(
      BuildContext context,
      List<File> files,
      Future<void> Function() onFinished,
    );

typedef SharedFileNavigationWaiter = Future<void> Function();

typedef SharedFileNavigatorResolver =
    NavigatorState? Function(GlobalKey<NavigatorState> navigatorKey);

abstract interface class FinTrackPlatformGateway {
  const factory FinTrackPlatformGateway.native() =
      NativeFinTrackPlatformGateway;

  void configureSharedFileListener(
    Future<void> Function(List<String> paths)? listener,
  );

  Future<List<String>> pendingSharedFiles();
}

class NativeFinTrackPlatformGateway implements FinTrackPlatformGateway {
  const NativeFinTrackPlatformGateway();

  @override
  void configureSharedFileListener(
    Future<void> Function(List<String> paths)? listener,
  ) {
    FinTrackPlatform.configureSharedFileListener(listener);
  }

  @override
  Future<List<String>> pendingSharedFiles() {
    return FinTrackPlatform.pendingSharedFiles();
  }
}

class FinTrackApp extends StatefulWidget {
  const FinTrackApp({
    super.key,
    required this.dependencies,
    this.initialConfiguration,
    this.platformGateway = const FinTrackPlatformGateway.native(),
    this.sharedFilePageBuilder = _defaultSharedFilePageBuilder,
    this.sharedFileBatchPageBuilder = _defaultSharedFileBatchPageBuilder,
    this.waitBeforeSharedFileNavigation = _defaultSharedFileNavigationWaiter,
    this.navigatorResolver = _defaultSharedFileNavigatorResolver,
  });

  final FinTrackDependencies dependencies;
  final Configuration? initialConfiguration;
  final FinTrackPlatformGateway platformGateway;
  final SharedFilePageBuilder sharedFilePageBuilder;
  final SharedFileBatchPageBuilder sharedFileBatchPageBuilder;
  final SharedFileNavigationWaiter waitBeforeSharedFileNavigation;
  final SharedFileNavigatorResolver navigatorResolver;

  @override
  State<FinTrackApp> createState() => _FinTrackAppState();
}

Widget _defaultSharedFilePageBuilder(
  BuildContext context,
  File file,
  Future<void> Function() onFinished,
) {
  return ProcessingPage(file: file, onFinished: onFinished);
}

Widget _defaultSharedFileBatchPageBuilder(
  BuildContext context,
  List<File> files,
  Future<void> Function() onFinished,
) {
  return ReceiptBatchProcessingPage(files: files, onFinished: onFinished);
}

Future<void> _defaultSharedFileNavigationWaiter() {
  return WidgetsBinding.instance.endOfFrame;
}

NavigatorState? _defaultSharedFileNavigatorResolver(
  GlobalKey<NavigatorState> navigatorKey,
) {
  return navigatorKey.currentState;
}

class _FinTrackAppState extends State<FinTrackApp> with WidgetsBindingObserver {
  static const _backupAutomaticPolicy = BackupAutomaticPolicy();

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _authGateKey = GlobalKey<AuthenticationGateState>();
  final _processingFiles = <String>{};
  Future<void>? _automaticBackupInProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.platformGateway.configureSharedFileListener(_processSharedFiles);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeInitialSharedFile();
      _resumePendingBatchImport();
      _runAutomaticBackupIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.platformGateway.configureSharedFileListener(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAutomaticBackupIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: StreamBuilder<Configuration>(
        initialData: widget.initialConfiguration,
        stream: widget.dependencies.configurationService.watch(),
        builder: (context, snapshot) {
          final themeMode =
              snapshot.data?.visualThemeMode ?? VisualThemeMode.dark;
          return MaterialApp(
            navigatorKey: _navigatorKey,
            navigatorObservers: [_StorageSnackBarRouteObserver()],
            title: widget.dependencies.appConfig.app.displayName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) => AuthenticationGate(
              key: _authGateKey,
              navigatorKey: _navigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
            theme: themeMode == VisualThemeMode.light
                ? FinTrackTheme.light()
                : FinTrackTheme.dark(),
            home: const FinTrackShell(),
          );
        },
      ),
    );
  }

  Future<void> _consumeInitialSharedFile() async {
    final paths = await widget.platformGateway.pendingSharedFiles();
    if (paths.isEmpty) {
      return;
    }
    await _processSharedFiles(paths);
  }

  Future<void> _runAutomaticBackupIfNeeded() async {
    final inProgress = _automaticBackupInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final future = _runAutomaticBackupIfNeededWithFeedback();
    _automaticBackupInProgress = future;
    await future.whenComplete(() => _automaticBackupInProgress = null);
  }

  Future<void> _runAutomaticBackupIfNeededWithFeedback() async {
    try {
      final configuration = await _loadConfigurationForAutomaticBackup();
      if (configuration == null) {
        await widget.dependencies.backupService.runAutomaticBackupIfNeeded();
        return;
      }

      final shouldShowProgress =
          _backupAutomaticPolicy.canRun(configuration) &&
          _backupAutomaticPolicy.isDue(configuration, DateTime.now());
      if (!shouldShowProgress || !mounted) {
        await widget.dependencies.backupService.runAutomaticBackupIfNeeded();
        return;
      }

      final backupContext = _navigatorKey.currentContext;
      final backupText = widget.dependencies.appConfig.ui.backup;
      if (backupContext == null || !backupContext.mounted) {
        await widget.dependencies.backupService.runAutomaticBackupIfNeeded();
        return;
      }

      await runWithBlockingProgress<void>(
        context: backupContext,
        title: backupText.backupInProgress,
        message: backupText.backupInProgressMessage,
        action: (_) async {
          await widget.dependencies.backupService.runAutomaticBackupIfNeeded();
        },
      );
    } catch (error, stackTrace) {
      FinTrackErrorLog.record(error, stackTrace);
    }
  }

  Future<Configuration?> _loadConfigurationForAutomaticBackup() async {
    try {
      return await widget.dependencies.configurationService.load();
    } catch (error, stackTrace) {
      FinTrackErrorLog.record(error, stackTrace);
      return null;
    }
  }

  Future<void> _resumePendingBatchImport() async {
    try {
      final snapshot = await widget.dependencies.receiptBatchImportService
          .findLatestOpenSnapshot();
      if (snapshot == null || !mounted) {
        return;
      }
      final navigator = widget.navigatorResolver(_navigatorKey);
      if (navigator == null) {
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptBatchProcessingPage(
            files: const <File>[],
            sessionId: snapshot.session.id,
          ),
        ),
      );
    } catch (error, stackTrace) {
      FinTrackErrorLog.record(error, stackTrace);
    }
  }

  Future<void> _processSharedFiles(List<String> paths) async {
    final newPaths = paths
        .where((path) => path.isNotEmpty)
        .where(_processingFiles.add)
        .toList();
    if (newPaths.isEmpty) {
      return;
    }

    try {
      final navigator = widget.navigatorResolver(_navigatorKey);
      if (navigator == null || !mounted || _authGateKey.currentState == null) {
        _processingFiles.removeAll(newPaths);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _processSharedFiles(newPaths);
          }
        });
        return;
      }

      final authenticated = await _authGateKey.currentState!
          .ensureAuthenticated(
            reason:
                'Confirme sua identidade para importar o comprovante recebido.',
          );
      if (!authenticated || !mounted) {
        await _deleteTemporaryFiles(newPaths);
        return;
      }

      final files = <File>[];
      for (final path in newPaths) {
        final file = File(path);
        if (await file.exists()) {
          files.add(file);
        }
      }
      if (files.isEmpty) {
        return;
      }
      try {
        for (final file in files) {
          await widget.dependencies.receiptService.validateSpaceForNewReceipt(
            file,
          );
        }
      } catch (error) {
        if (!mounted) {
          return;
        }
        final snackContext = _navigatorKey.currentContext;
        if (snackContext != null &&
            snackContext.mounted &&
            isStorageLimitError(error)) {
          showStorageLimitSnackBar(snackContext, error, avoidScanButton: true);
        }
        await _deleteTemporaryFiles(newPaths);
        return;
      }

      await widget.waitBeforeSharedFileNavigation();
      if (!mounted) {
        return;
      }
      final currentNavigator = widget.navigatorResolver(_navigatorKey);
      if (currentNavigator == null) {
        _processingFiles.removeAll(newPaths);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _processSharedFiles(newPaths);
          }
        });
        return;
      }

      if (files.length == 1) {
        await currentNavigator.push(
          MaterialPageRoute<void>(
            builder: (context) => widget.sharedFilePageBuilder(
              context,
              files.first,
              () => _deleteTemporaryFiles(newPaths),
            ),
          ),
        );
      } else {
        await currentNavigator.push(
          MaterialPageRoute<void>(
            builder: (context) => widget.sharedFileBatchPageBuilder(
              context,
              files,
              () => _deleteTemporaryFiles(newPaths),
            ),
          ),
        );
      }
    } finally {
      _processingFiles.removeAll(newPaths);
    }
  }

  Future<void> _deleteTemporaryFiles(List<String> paths) async {
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}

class _StorageSnackBarRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    hideStorageLimitSnackBarIfVisible();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    hideStorageLimitSnackBarIfVisible();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    hideStorageLimitSnackBarIfVisible();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    hideStorageLimitSnackBarIfVisible();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

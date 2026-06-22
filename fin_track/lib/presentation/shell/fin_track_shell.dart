import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/exceptions/operation_cancelled_exception.dart';
import '../../domain/entities/configuration.dart';
import '../camera/processing_page.dart';
import '../categories/pages/categories_page.dart';
import '../receipts/receipt_flow_result.dart';
import '../receipts/pages/receipt_list_page.dart';
import '../configuration/pages/configuration_page.dart';
import '../onboarding/onboarding_page.dart';
import '../reports/reports_page.dart';
import '../widgets/app_scope.dart';
import '../widgets/dialog_actions.dart';
import '../widgets/keyboard_back_dismissal.dart';
import '../widgets/state_views.dart';
import '../widgets/storage_limit_feedback.dart';
import 'widgets/fin_track_bottom_nav_bar.dart';

class FinTrackShell extends StatefulWidget {
  const FinTrackShell({super.key});

  @override
  State<FinTrackShell> createState() => _FinTrackShellState();
}

class _FinTrackShellState extends State<FinTrackShell>
    with SingleTickerProviderStateMixin {
  static const _navItemCount = 4;
  static const _swipeNavigationDistance = 80.0;
  static const _swipeNavigationVelocity = 350.0;
  static const _captureSearchDragDistance = 84.0;
  static const _captureSearchDragLimit = 124.0;
  static const _captureSearchDragDamping = 1.18;
  static const _captureSearchVelocity = 260.0;

  final _searchKey = GlobalKey<ReceiptListPageState>();
  final _categoriesKey = GlobalKey<CategoriesPageState>();
  late final AnimationController _captureAnimationController;
  Animation<double>? _captureAnimation;
  VoidCallback? _captureAnimationListener;
  var _selectedIndex = 0;
  var _swipePixels = 0.0;
  var _dragPixels = 0.0;
  var _capturing = false;

  @override
  void initState() {
    super.initState();
    _captureAnimationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _clearCaptureAnimationListener();
    _captureAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Configuration>(
      stream: AppScope.of(context).configurationService.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: LoadingView(message: 'Abrindo FinTrack'));
        }

        if (!snapshot.data!.onboardingCompleted) {
          return OnboardingPage(onFinished: () => setState(() {}));
        }

        final pages = <Widget>[
          ReceiptListPage(key: _searchKey, showScaffold: false),
          CategoriesPage(key: _categoriesKey),
          const ReportsPage(),
          ConfigurationPage(isActive: _selectedIndex == 3),
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            if (dismissKeyboardForBack(context)) {
              return;
            }
            if (_cancelSelectionForTab(_selectedIndex)) {
              return;
            }
            if (_clearSearchStateForTab(_selectedIndex)) {
              return;
            }
            if (_selectedIndex == 0) {
              SystemNavigator.pop();
              return;
            }
            _goToSearchTab();
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => hideStorageLimitSnackBarIfVisible(),
            child: Scaffold(
              body: SafeArea(
                bottom: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: _onSwipeNavigationUpdate,
                  onHorizontalDragEnd: _onSwipeNavigationEnd,
                  onHorizontalDragCancel: _onSwipeNavigationCancel,
                  child: IndexedStack(index: _selectedIndex, children: pages),
                ),
              ),
              bottomNavigationBar: FinTrackBottomNavBar(
                selectedIndex: _selectedIndex,
                dragProgress: (_dragPixels / _captureSearchDragDistance).clamp(
                  0,
                  1,
                ),
                captureBusy: _capturing,
                onSelect: _select,
                onCapture: _capture,
                onDragUpdate: _onCaptureDragUpdate,
                onDragEnd: _onCaptureDragEnd,
                onDragCancel: _onCaptureDragCancel,
              ),
            ),
          ),
        );
      },
    );
  }

  void _select(int index) {
    if (index == _selectedIndex || index < 0 || index >= _navItemCount) {
      return;
    }
    hideStorageLimitSnackBarIfVisible();
    _cancelSelectionForTab(_selectedIndex);
    setState(() => _selectedIndex = index);
  }

  void _goToSearchTab() {
    if (_selectedIndex == 0) {
      return;
    }
    hideStorageLimitSnackBarIfVisible();
    _cancelSelectionForTab(_selectedIndex);
    setState(() => _selectedIndex = 0);
  }

  bool _cancelSelectionForTab(int index) {
    return switch (index) {
      0 => _searchKey.currentState?.cancelSelectionMode() ?? false,
      1 => _categoriesKey.currentState?.cancelSelectionMode() ?? false,
      _ => false,
    };
  }

  bool _clearSearchStateForTab(int index) {
    return switch (index) {
      0 => _searchKey.currentState?.clearSearchStateIfNeeded() ?? false,
      1 => _categoriesKey.currentState?.clearSearchStateIfNeeded() ?? false,
      _ => false,
    };
  }

  void _onSwipeNavigationUpdate(DragUpdateDetails details) {
    _swipePixels += details.primaryDelta ?? details.delta.dx;
  }

  void _onSwipeNavigationEnd(DragEndDetails details) {
    final distance = _swipePixels;
    _swipePixels = 0;
    final velocity = details.primaryVelocity ?? 0;

    final next =
        distance <= -_swipeNavigationDistance ||
        velocity <= -_swipeNavigationVelocity;
    final previous =
        distance >= _swipeNavigationDistance ||
        velocity >= _swipeNavigationVelocity;

    if (next) {
      _select(_selectedIndex + 1);
    } else if (previous) {
      _select(_selectedIndex - 1);
    }
  }

  void _onSwipeNavigationCancel() {
    _swipePixels = 0;
  }

  Future<void> _capture() async {
    if (_capturing) {
      return;
    }

    hideStorageLimitSnackBarIfVisible();
    setState(() => _capturing = true);
    try {
      final service = AppScope.of(context).receiptService;
      await service.validateSpaceForNewReceipt();
      File file;
      try {
        file = await service.scanDocument();
      } catch (error) {
        if (isOperationCancelled(error)) {
          return;
        }
        if (!mounted) {
          return;
        }
        final useCamera = await _confirmSimpleCamera();
        if (useCamera != true || !mounted) {
          return;
        }
        file = await service.captureImage();
      }
      if (!mounted) {
        return;
      }
      await service.validateSpaceForNewReceipt(file);
      if (!mounted) {
        return;
      }
      final result = await Navigator.of(context).push<ReceiptFlowResult>(
        MaterialPageRoute<ReceiptFlowResult>(
          builder: (_) => ProcessingPage(file: file),
        ),
      );
      if (!mounted) {
        return;
      }
      if (result == ReceiptFlowResult.saved) {
        _goToSearchTab();
      }
    } catch (error) {
      if (isOperationCancelled(error)) {
        return;
      }
      if (mounted) {
        if (isStorageLimitError(error)) {
          showStorageLimitSnackBar(context, error, avoidScanButton: true);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível capturar o comprovante.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<bool?> _confirmSimpleCamera() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner indisponível'),
        content: const Text(
          'Não foi possível abrir o scanner de documentos. Deseja capturar com a câmera simples?',
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Usar câmera'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onCaptureDragUpdate(DragUpdateDetails details) {
    _captureAnimationController.stop();
    _clearCaptureAnimationListener();
    setState(() {
      final dampedDelta = -details.delta.dy * _captureSearchDragDamping;
      _dragPixels = (_dragPixels + dampedDelta).clamp(
        0,
        _captureSearchDragLimit,
      );
    });
  }

  void _onCaptureDragEnd(DragEndDetails details) {
    final upwardVelocity = -details.velocity.pixelsPerSecond.dy;
    final projectedPixels = _dragPixels + (upwardVelocity * 0.12);
    final shouldSearch =
        projectedPixels >= _captureSearchDragDistance ||
        upwardVelocity >= _captureSearchVelocity;
    if (shouldSearch) {
      _animateCaptureDrag(
        _captureSearchDragLimit,
        const Duration(milliseconds: 360),
        Curves.easeOutCubic,
        onComplete: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _selectedIndex = 0;
          });
          _searchKey.currentState?.focusSearch();
          _animateCaptureDrag(
            0,
            const Duration(milliseconds: 520),
            Curves.easeOutQuart,
          );
        },
      );
      return;
    }
    _animateCaptureDrag(
      0,
      const Duration(milliseconds: 460),
      Curves.easeOutQuart,
    );
  }

  void _onCaptureDragCancel() {
    _animateCaptureDrag(
      0,
      const Duration(milliseconds: 420),
      Curves.easeOutQuart,
    );
  }

  void _animateCaptureDrag(
    double target,
    Duration duration,
    Curve curve, {
    VoidCallback? onComplete,
  }) {
    _captureAnimationController.stop();
    _clearCaptureAnimationListener();
    final begin = _dragPixels;
    final animation = Tween<double>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _captureAnimationController, curve: curve),
    );
    _captureAnimation = animation;

    void listener() {
      if (mounted) {
        setState(() => _dragPixels = animation.value);
      }
    }

    _captureAnimationListener = listener;
    _captureAnimationController
      ..duration = duration
      ..reset();
    animation.addListener(listener);
    _captureAnimationController.forward().whenComplete(() {
      _clearCaptureAnimationListener();
      if (mounted) {
        setState(() => _dragPixels = target);
      }
      onComplete?.call();
    });
  }

  void _clearCaptureAnimationListener() {
    final animation = _captureAnimation;
    final listener = _captureAnimationListener;
    if (animation != null && listener != null) {
      animation.removeListener(listener);
    }
    _captureAnimation = null;
    _captureAnimationListener = null;
  }
}

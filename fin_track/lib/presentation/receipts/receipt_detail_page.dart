import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/receipt.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import '../theme/fin_track_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/category_visuals.dart';
import '../widgets/destructive_filled_button.dart';
import '../widgets/dialog_actions.dart';
import '../widgets/fin_track_page_header.dart';
import '../widgets/formatters.dart';
import '../widgets/state_views.dart';
import 'pages/receipt_confirmation_page.dart';
import 'widgets/receipt_detail_widgets.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({super.key, required this.receiptId});

  final int receiptId;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  var _loadRequested = false;
  var _loading = true;
  Object? _error;
  Receipt? _receipt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadRequested) {
      _loadRequested = true;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    final detailText = AppScope.of(context).appConfig.ui.receiptDetail;
    final commonText = AppScope.of(context).appConfig.ui.common;
    return Scaffold(
      appBar: FinTrackPageHeader(
        automaticallyImplyLeading: true,
        title: Text(detailText.title),
        actions: [
          PopupMenuButton<_DetailAction>(
            tooltip: detailText.moreOptionsTooltip,
            enabled: receipt != null,
            icon: Icon(Icons.more_vert),
            constraints: const BoxConstraints.tightFor(width: 56),
            onSelected: receipt == null
                ? null
                : (action) => _runAction(receipt, action),
            itemBuilder: (context) => [
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.edit,
                child: ReceiptDetailActionMenuIcon(
                  tooltip: commonText.edit,
                  icon: Icons.edit_outlined,
                ),
              ),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.share,
                child: ReceiptDetailActionMenuIcon(
                  tooltip: commonText.share,
                  icon: Icons.share_outlined,
                ),
              ),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.save,
                child: ReceiptDetailActionMenuIcon(
                  tooltip: commonText.saveToDevice,
                  icon: Icons.download_outlined,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.delete,
                child: ReceiptDetailActionMenuIcon(
                  tooltip: commonText.delete,
                  icon: Icons.delete_outline,
                  color: context.finTrackColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final detailText = AppScope.of(context).appConfig.ui.receiptDetail;
    if (_loading) {
      return LoadingView(message: detailText.loading);
    }
    final receipt = _receipt;
    if (_error != null || receipt == null) {
      return ErrorStateView(message: detailText.loadError, onRetry: _load);
    }

    final receiptData = receipt.extractedData;
    final natureColor = receipt.expense
        ? context.finTrackColors.expense
        : context.finTrackColors.income;
    final neutralColor = context.finTrackColors.neutralAccent;
    final category = receipt.category;
    final categoryColor = category == null
        ? neutralColor
        : categoryColorFor(category, context);
    final backupColor = receipt.cloudSynced
        ? context.finTrackColors.income
        : neutralColor;
    final establishment = receiptData?.establishment ?? '';
    final amount = receiptData?.amount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        FutureBuilder<File>(
          future: AppScope.of(context).receiptService.exportFile(receipt.id),
          builder: (context, fileSnapshot) {
            final file = fileSnapshot.data;
            return ReceiptDetailImagePreview(
              file: file,
              fileName: receipt.fileName,
              fileType: receipt.fileType,
            );
          },
        ),
        const SizedBox(height: 16),
        ReceiptDetailSectionHeader(
          icon: Icons.receipt_long_outlined,
          title: detailText.summaryTitle,
          color: neutralColor,
        ),
        const SizedBox(height: 8),
        ReceiptDetailPanel(
          color: neutralColor,
          children: [
            ReceiptDetailInfoRow(
              icon: Icons.storefront_outlined,
              title: detailText.establishment,
              chip: ReceiptDetailChip(
                label: establishment,
                color: neutralColor,
                semanticLabel: establishment.isEmpty
                    ? 'Estabelecimento não identificado'
                    : 'Estabelecimento: $establishment',
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: neutralColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              color: neutralColor,
            ),
            ReceiptDetailInfoRow(
              icon: Icons.payments_outlined,
              title: detailText.value,
              chip: ReceiptDetailChip(
                label: formatCurrency(amount),
                color: natureColor,
                semanticLabel: amount == null
                    ? 'Valor não identificado'
                    : 'Valor: ${formatCurrencyForSpeech(amount)}',
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: natureColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              color: natureColor,
            ),
            ReceiptDetailInfoRow(
              icon: receipt.expense
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              title: detailText.nature,
              chip: ReceiptDetailChip(
                label: receipt.expense ? detailText.expense : detailText.income,
                color: natureColor,
                semanticLabel:
                    'Natureza: ${receipt.expense ? detailText.expense : detailText.income}',
              ),
              color: natureColor,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ReceiptDetailSectionHeader(
          icon: Icons.subject_outlined,
          title: detailText.dataTitle,
          color: neutralColor,
        ),
        const SizedBox(height: 8),
        ReceiptDetailPanel(
          color: neutralColor,
          children: [
            ReceiptDetailInfoRow(
              icon: Icons.calendar_month_outlined,
              title: detailText.date,
              chip: ReceiptDetailChip(
                label: formatDate(receiptData?.transactionDate),
                color: neutralColor,
                semanticLabel:
                    'Data: ${formatDate(receiptData?.transactionDate)}',
              ),
              color: neutralColor,
            ),
            ReceiptDetailInfoRow(
              icon: Icons.credit_card_outlined,
              title: detailText.paymentMethod,
              chip: ReceiptDetailChip(
                label: receiptData?.paymentMethod ?? detailText.unidentified,
                color: neutralColor,
                semanticLabel:
                    'Forma de pagamento: ${receiptData?.paymentMethod ?? detailText.unidentified}',
              ),
              color: neutralColor,
            ),
            ReceiptDetailInfoRow(
              icon: Icons.receipt_outlined,
              title: detailText.receiptType,
              chip: ReceiptDetailChip(
                label: receipt.type.label,
                color: categoryColor,
                semanticLabel: 'Tipo de comprovante: ${receipt.type.label}',
              ),
              color: categoryColor,
            ),
            ReceiptDetailInfoRow(
              icon: category == null
                  ? Icons.category_outlined
                  : categoryIconFor(category),
              title: detailText.category,
              chip: category == null
                  ? ReceiptDetailChip(
                      label: detailText.withoutCategory,
                      color: neutralColor,
                      semanticLabel: 'Categoria não definida',
                    )
                  : ReceiptDetailChip.category(category, context),
              color: categoryColor,
            ),
            ReceiptDetailInfoRow(
              icon: receipt.cloudSynced
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              title: commonText.backup,
              chip: ReceiptDetailChip(
                label: receipt.cloudSynced
                    ? detailText.synced
                    : detailText.local,
                color: backupColor,
                semanticLabel:
                    'Backup: ${receipt.cloudSynced ? detailText.synced : detailText.local}',
              ),
              color: backupColor,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final receipt = await AppScope.of(
        context,
      ).receiptService.findById(widget.receiptId);
      if (!mounted) {
        return;
      }
      setState(() {
        _receipt = receipt;
        _loading = false;
      });
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao carregar detalhes do comprovante',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _runAction(Receipt receipt, _DetailAction action) {
    switch (action) {
      case _DetailAction.edit:
        _edit(receipt);
        break;
      case _DetailAction.share:
        _share(receipt.id);
        break;
      case _DetailAction.save:
        _saveToDevice(receipt.id);
        break;
      case _DetailAction.delete:
        _confirmDeletion(receipt);
        break;
    }
  }

  Future<void> _edit(Receipt receipt) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReceiptConfirmationPage(receiptId: receipt.id),
      ),
    );
    if (updated != true || !mounted) {
      return;
    }
    await _load();
  }

  Future<void> _share(int id) async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final service = AppScope.of(context).receiptService;
    try {
      await service.shareImage(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(commonText.shareOpened)));
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao compartilhar comprovante',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(commonText.shareFailed)));
    }
  }

  Future<void> _saveToDevice(int id) async {
    final filesText = AppScope.of(context).appConfig.ui.receipts.files;
    final service = AppScope.of(context).receiptService;
    try {
      await service.saveImageToDevice(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(filesText.fileSaved)));
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao salvar comprovante no dispositivo',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(filesText.fileSaveFailed)));
    }
  }

  Future<void> _confirmDeletion(Receipt receipt) async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final detailText = AppScope.of(context).appConfig.ui.receiptDetail;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(detailText.deleteTitle),
        content: Text(detailText.deleteMessage),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(commonText.cancel),
              ),
              FilledButton.icon(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.delete_outline),
                label: Text(commonText.delete),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    await AppScope.of(context).receiptService.delete(receipt.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(detailText.deleted)));
    Navigator.pop(context);
  }
}

enum _DetailAction { edit, share, save, delete }

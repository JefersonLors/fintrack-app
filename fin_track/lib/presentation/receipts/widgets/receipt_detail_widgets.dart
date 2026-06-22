import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/fin_track_chip.dart';
import '../../widgets/fin_track_panel.dart';
import '../../widgets/image_viewer_page.dart';

class ReceiptDetailActionMenuIcon extends StatelessWidget {
  const ReceiptDetailActionMenuIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Center(child: Icon(icon, color: color)),
    );
  }
}

class ReceiptDetailImagePreview extends StatelessWidget {
  const ReceiptDetailImagePreview({
    super.key,
    required this.file,
    required this.fileName,
    required this.fileType,
  });

  final File? file;
  final String fileName;
  final String fileType;

  @override
  Widget build(BuildContext context) {
    final isImage = _looksLikeImage(fileType, fileName);
    final preview = AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: file == null
                  ? const CircularProgressIndicator()
                  : isImage
                  ? Image.file(
                      file!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          ReceiptDetailFilePreviewFallback(
                            fileName: fileName,
                            fileType: fileType,
                          ),
                    )
                  : ReceiptDetailFilePreviewFallback(
                      fileName: fileName,
                      fileType: fileType,
                    ),
            ),
          ),
        ),
      ),
    );
    if (file == null || !isImage) {
      return preview;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ImageViewerPage(file: file!, title: 'Imagem do comprovante'),
        ),
      ),
      child: preview,
    );
  }
}

class ReceiptDetailFilePreviewFallback extends StatelessWidget {
  const ReceiptDetailFilePreviewFallback({
    super.key,
    required this.fileName,
    required this.fileType,
  });

  final String fileName;
  final String fileType;

  @override
  Widget build(BuildContext context) {
    final isPdf = fileType.toLowerCase().contains('pdf');
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            _displayFileName(fileName),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ReceiptDetailSectionHeader extends StatelessWidget {
  const ReceiptDetailSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.finTrackColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class ReceiptDetailPanel extends StatelessWidget {
  const ReceiptDetailPanel({
    super.key,
    required this.color,
    required this.children,
  });

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FinTrackDividedPanel(
      borderColor: color.withValues(alpha: 0.24),
      children: children,
    );
  }
}

class ReceiptDetailInfoRow extends StatelessWidget {
  const ReceiptDetailInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.chip,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Widget chip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailIcon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.finTrackColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerLeft, child: chip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptDetailChip extends StatelessWidget {
  const ReceiptDetailChip({
    super.key,
    required this.label,
    required this.color,
    this.textStyle,
    this.semanticLabel,
    this.tooltip,
  });

  factory ReceiptDetailChip.category(Category category, BuildContext context) {
    return ReceiptDetailChip(
      label: category.name,
      color: categoryColorFor(category, context),
      semanticLabel: 'Categoria: ${category.name}',
    );
  }

  final String label;
  final Color color;
  final TextStyle? textStyle;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return FinTrackChip(
      label: label,
      color: color,
      maxWidth: 260,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      semanticLabel: semanticLabel,
      tooltip: tooltip ?? semanticLabel,
      textStyle:
          textStyle ??
          Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DetailIcon extends StatelessWidget {
  const _DetailIcon(this.icon, {required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

bool _looksLikeImage(String fileType, String fileName) {
  final type = fileType.toLowerCase();
  final name = fileName.toLowerCase();
  return type.startsWith('image/') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.webp') ||
      name.endsWith('.heic') ||
      name.endsWith('.heif');
}

String _displayFileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

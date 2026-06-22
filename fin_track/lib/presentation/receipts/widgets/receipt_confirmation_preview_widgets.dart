import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';
import '../../widgets/image_viewer_page.dart';
import '../receipt_form_helpers.dart';

class ReceiptConfirmationImagePreview extends StatelessWidget {
  const ReceiptConfirmationImagePreview({
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
    final isImage = looksLikeReceiptImage(fileType, fileName);
    final preview = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.finTrackColors.borderStrong),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: file == null
                      ? const CircularProgressIndicator()
                      : _previewContent(isImage),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (file == null || !isImage) {
      return preview;
    }
    // coverage:ignore-start
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openReceiptConfirmationImagePreview(context, file!),
      child: preview,
    );
    // coverage:ignore-end
  }

  Widget _previewContent(bool isImage) {
    if (!isImage) {
      return _FilePreviewFallback(fileName: fileName, fileType: fileType);
    }
    // coverage:ignore-start
    return Image.file(
      file!,
      fit: BoxFit.contain,
      errorBuilder: _fallbackBuilder,
    );
    // coverage:ignore-end
  }

  // coverage:ignore-start
  Widget _fallbackBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return _FilePreviewFallback(fileName: fileName, fileType: fileType);
  }

  // coverage:ignore-end
}

// coverage:ignore-start
void openReceiptConfirmationImagePreview(BuildContext context, File file) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ImageViewerPage(file: file, title: 'Imagem do comprovante'),
    ),
  );
}
// coverage:ignore-end

class _FilePreviewFallback extends StatelessWidget {
  const _FilePreviewFallback({required this.fileName, required this.fileType});

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
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            'Pré-visualização indisponível',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

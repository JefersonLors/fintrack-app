import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({super.key, required this.file, required this.title});

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

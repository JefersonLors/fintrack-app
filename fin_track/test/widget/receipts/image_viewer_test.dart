import 'dart:io';

import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('image viewer builds viewer for provided file', (tester) async {
    final file = File('${Directory.systemTemp.path}/fintrack-missing.png');

    await tester.pumpWidget(
      _host(ImageViewerPage(file: file, title: 'Imagem')),
    );
    await tester.pump();

    expect(find.text('Imagem'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}

Widget _host(Widget child) {
  return MaterialApp(theme: FinTrackTheme.light(), home: child);
}

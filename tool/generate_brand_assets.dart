// Rasterises the vector brand mark into the PNG files used by
// `flutter_launcher_icons` and by the web manifest.
//
// Run with:  flutter test tool/generate_brand_assets.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gexpenses/core/branding/brand_mark.dart';

Future<void> _export(String path, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const BrandMarkPainter(
    showBackground: true,
  ).paint(canvas, Size.square(size.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${size}px)');
}

void main() {
  testWidgets('exports brand assets', (tester) async {
    await tester.runAsync(() async {
      await _export('assets/branding/logo_mark.png', 1024);
      await _export('assets/branding/logo_mark_512.png', 512);
    });
  });
}

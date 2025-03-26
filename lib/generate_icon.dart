import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:path/path.dart';

void main() async {
  // Create directory if it doesn't exist
  final directory = Directory('assets/icon');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  await generateIcon(
    text: 'N',
    backgroundColor: const Color(0xFFd2982a),
    textColor: Colors.white,
    outputPath: 'assets/icon/icon.png',
    size: 1024,
    withBackground: true,
  );

  await generateIcon(
    text: 'N',
    backgroundColor: Colors.transparent,
    textColor: Colors.white,
    outputPath: 'assets/icon/icon_foreground.png',
    size: 1024,
    withBackground: false,
  );

  print('Icon files generated successfully:');
  print('- ${join(Directory.current.path, 'assets/icon/icon.png')}');
  print('- ${join(Directory.current.path, 'assets/icon/icon_foreground.png')}');
}

Future<void> generateIcon({
  required String text,
  required Color backgroundColor,
  required Color textColor,
  required String outputPath,
  required int size,
  required bool withBackground,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = backgroundColor;

  // Draw background if needed
  if (withBackground) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );
  }

  // Draw text
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: size * 0.6,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  // Convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  // Save to file
  final file = File(outputPath);
  await file.writeAsBytes(pngBytes!.buffer.asUint8List());
}

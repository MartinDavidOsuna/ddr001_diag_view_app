import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

abstract interface class OdometerRecognitionPort {
  Future<String> recognize(String imagePath);
  Future<List<RecognizedTextRegion>> recognizeRegions(String imagePath);
  Future<void> dispose();
}

final class RecognizedTextRegion {
  const RecognizedTextRegion({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final String text;
  final double left, top, width, height;
}

final class MlKitOdometerRecognitionAdapter implements OdometerRecognitionPort {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<String> recognize(String imagePath) async {
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return recognized.text;
  }

  @override
  Future<List<RecognizedTextRegion>> recognizeRegions(String imagePath) async {
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    final decoded = img.decodeImage(await File(imagePath).readAsBytes());
    final imageWidth = (decoded?.width ?? 1).toDouble();
    final imageHeight = (decoded?.height ?? 1).toDouble();
    return recognized.blocks
        .map(
          (block) => RecognizedTextRegion(
            text: block.text,
            left: (block.boundingBox.left / imageWidth).clamp(0, 1),
            top: (block.boundingBox.top / imageHeight).clamp(0, 1),
            width: (block.boundingBox.width / imageWidth).clamp(.01, 1),
            height: (block.boundingBox.height / imageHeight).clamp(.01, 1),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}

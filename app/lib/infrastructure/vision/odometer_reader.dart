import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract interface class OdometerRecognitionPort {
  Future<String> recognize(String imagePath);
  Future<void> dispose();
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
  Future<void> dispose() => _recognizer.close();
}

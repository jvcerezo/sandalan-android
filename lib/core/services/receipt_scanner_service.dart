import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_parser.dart';

/// Scans receipt images using Google ML Kit text recognition (thin variant).
class ReceiptScannerService {
  ReceiptScannerService._();
  static final instance = ReceiptScannerService._();

  /// Scan a receipt image and return parsed data.
  /// [imagePath] — absolute path to the image file.
  Future<ParsedReceipt> scan(String imagePath) async {
    // Verify the file exists and is readable before invoking ML Kit.
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Receipt image not found at: $imagePath');
    }
    final bytes = await file.length();
    if (bytes == 0) {
      throw Exception('Receipt image is empty (0 bytes)');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      if (rawText.trim().isEmpty) {
        return const ParsedReceipt(rawText: '');
      }

      return ReceiptParser.parse(rawText);
    } finally {
      await textRecognizer.close();
    }
  }
}

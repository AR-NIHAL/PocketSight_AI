import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/entities/ocr_candidate.dart';
import '../../domain/services/serial_candidate_parser.dart';

class MlKitOcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Processes an image from the file system and returns extracted serial/model candidates.
  Future<List<OcrCandidate>> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final List<String> lines = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        lines.add(line.text);
      }
    }

    return SerialCandidateParser.parse(lines);
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}

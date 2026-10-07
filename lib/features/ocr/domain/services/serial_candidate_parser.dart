import '../entities/ocr_candidate.dart';

class SerialCandidateParser {
  static final RegExp _serialPrefixRegex = RegExp(
    r'(?:(?:S/?N|SERIAL\s*(?:NO|NUM|NUMBER)?|SERVICE\s*TAG(?:\s*\(S/N\))?|SNID|ST))\s*[:=\-\s]\s*([A-Za-z0-9\-]{5,26})',
    caseSensitive: false,
  );

  static final RegExp _modelPrefixRegex = RegExp(
    r'(?:(?:MODEL(?:\s*(?:NO|NUM|NAME))?|PROD(?:UCT)?\s*(?:ID|NAME)?|MTM|REG\s*MODEL))\s*[:=\-\s]\s*([A-Za-z0-9\-#\/]{3,26})',
    caseSensitive: false,
  );

  static final RegExp _standaloneCodeRegex = RegExp(
    r'\b(?=[A-Za-z0-9\-]{6,22}\b)(?=[A-Za-z0-9\-]*\d)(?=[A-Za-z0-9\-]*[A-Za-z])[A-Za-z0-9\-]{6,22}\b',
  );

  static final Set<String> _ignoredWords = {
    'NOTEBOOK',
    'LAPTOP',
    'WINDOWS',
    'PRODUCT',
    'SERVICE',
    'SERIAL',
    'NUMBER',
    'MANUFACTURED',
    'RATING',
    'ENERGY',
    'OUTPUT',
    'INPUT',
    'SHENZHEN',
    'COMPLIES',
    'CANADA',
    'CHINESE',
    'VIETNAM',
    'TAIWAN',
    'BATTERY',
    'ADAPTER',
    'CHARGER',
    'LENOVO',
    'HEWLETT',
    'PACKARD',
  };

  /// Parses raw recognized text or lines and returns extracted candidates.
  static List<OcrCandidate> parse(List<String> rawLines) {
    final List<OcrCandidate> candidates = [];
    final Set<String> seenValues = {};

    void addCandidate(String val, CandidateType type, double conf, String line) {
      final cleanVal = val.trim().replaceAll(RegExp(r'[^\w\-]'), '');
      if (cleanVal.length < 4 || cleanVal.length > 28) return;
      if (_ignoredWords.contains(cleanVal.toUpperCase())) return;

      if (!seenValues.contains(cleanVal.toUpperCase())) {
        seenValues.add(cleanVal.toUpperCase());
        candidates.add(OcrCandidate(
          value: cleanVal,
          type: type,
          confidence: conf,
          sourceLine: line.trim(),
        ));
      }
    }

    for (final line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 1. Explicit Serial matches
      final serialMatch = _serialPrefixRegex.firstMatch(trimmed);
      if (serialMatch != null && serialMatch.groupCount >= 1) {
        final matchStr = serialMatch.group(1);
        if (matchStr != null && matchStr.isNotEmpty) {
          addCandidate(matchStr, CandidateType.serial, 0.98, trimmed);
        }
      }

      // 2. Explicit Model matches
      final modelMatch = _modelPrefixRegex.firstMatch(trimmed);
      if (modelMatch != null && modelMatch.groupCount >= 1) {
        final matchStr = modelMatch.group(1);
        if (matchStr != null && matchStr.isNotEmpty) {
          addCandidate(matchStr, CandidateType.model, 0.95, trimmed);
        }
      }

      // 3. Fallback standalone alphanumeric tokens
      for (final match in _standaloneCodeRegex.allMatches(trimmed)) {
        final token = match.group(0);
        if (token != null && token.isNotEmpty) {
          addCandidate(token, CandidateType.general, 0.75, trimmed);
        }
      }
    }

    // Sort: serials first, then models, then general tokens
    candidates.sort((a, b) {
      final priority = {
        CandidateType.serial: 0,
        CandidateType.model: 1,
        CandidateType.general: 2,
      };
      final comp = priority[a.type]!.compareTo(priority[b.type]!);
      if (comp != 0) return comp;
      return b.confidence.compareTo(a.confidence);
    });

    return candidates;
  }
}

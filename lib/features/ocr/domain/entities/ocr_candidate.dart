enum CandidateType {
  serial,
  model,
  general;

  String get label {
    switch (this) {
      case CandidateType.serial:
        return 'Serial Number (S/N)';
      case CandidateType.model:
        return 'Model / Product';
      case CandidateType.general:
        return 'Detected Code';
    }
  }
}

class OcrCandidate {
  final String value;
  final CandidateType type;
  final double confidence;
  final String sourceLine;

  const OcrCandidate({
    required this.value,
    required this.type,
    this.confidence = 0.9,
    required this.sourceLine,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrCandidate &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

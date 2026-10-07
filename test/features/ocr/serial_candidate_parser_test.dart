import 'package:flutter_test/flutter_test.dart';
import 'package:pocketsite_ai/features/ocr/domain/entities/ocr_candidate.dart';
import 'package:pocketsite_ai/features/ocr/domain/services/serial_candidate_parser.dart';

void main() {
  group('SerialCandidateParser', () {
    test('extracts Dell Service Tag as serial candidate', () {
      final lines = [
        'DELL INSPIRON 15',
        'Service Tag (S/N): 7B3K9X2',
        'Express Service Code: 15938472910',
        'Mfg Year: 2022',
      ];

      final results = SerialCandidateParser.parse(lines);
      expect(results, isNotEmpty);
      expect(results.any((c) => c.value == '7B3K9X2' && c.type == CandidateType.serial), isTrue);
    });

    test('extracts HP Serial and Product ID', () {
      final lines = [
        'HP Pavilion 14',
        'Serial: 5CD1234XYZ',
        'Product ID: 2V8G6EA',
        'Model: 14-ce3000',
      ];

      final results = SerialCandidateParser.parse(lines);
      expect(results.any((c) => c.value == '5CD1234XYZ' && c.type == CandidateType.serial), isTrue);
      expect(results.any((c) => c.value == '14-ce3000' && c.type == CandidateType.model), isTrue);
    });

    test('extracts Lenovo S/N and MTM', () {
      final lines = [
        'Lenovo ThinkPad T480',
        'S/N: PF2ABC12',
        'MTM: 20W4002GUS',
      ];

      final results = SerialCandidateParser.parse(lines);
      expect(results.any((c) => c.value == 'PF2ABC12' && c.type == CandidateType.serial), isTrue);
      expect(results.any((c) => c.value == '20W4002GUS' && c.type == CandidateType.model), isTrue);
    });

    test('extracts Asus Serial Number and Model', () {
      final lines = [
        'ASUSTeK COMPUTER INC.',
        'Model: UX434F',
        'Serial No: L8N0CV012345678',
      ];

      final results = SerialCandidateParser.parse(lines);
      expect(results.any((c) => c.value == 'L8N0CV012345678' && c.type == CandidateType.serial), isTrue);
      expect(results.any((c) => c.value == 'UX434F' && c.type == CandidateType.model), isTrue);
    });

    test('ignores common English noise words', () {
      final lines = [
        'NOTEBOOK PC',
        'MADE IN CHINA',
        'RATING 19.5V 3.33A',
        'CHARGER ADAPTER',
      ];

      final results = SerialCandidateParser.parse(lines);
      expect(results, isEmpty);
    });
  });
}

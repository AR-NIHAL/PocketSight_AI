import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/ocr_candidate.dart';

class OcrReviewResult {
  final String? serialNumber;
  final String? model;
  final bool isVerified;
  final String? missingReason;
  final String imagePath;
  final bool retakePhoto;

  const OcrReviewResult({
    this.serialNumber,
    this.model,
    required this.isVerified,
    this.missingReason,
    required this.imagePath,
    this.retakePhoto = false,
  });
}

class OcrReviewSheet extends StatefulWidget {
  final String imagePath;
  final List<OcrCandidate> candidates;

  const OcrReviewSheet({
    super.key,
    required this.imagePath,
    required this.candidates,
  });

  @override
  State<OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends State<OcrReviewSheet> {
  late TextEditingController _serialController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    // Pre-populate best serial and model candidates if available
    final bestSerial = widget.candidates
        .where((c) => c.type == CandidateType.serial)
        .firstOrNull
        ?.value;

    final bestModel = widget.candidates
        .where((c) => c.type == CandidateType.model)
        .firstOrNull
        ?.value;

    _serialController = TextEditingController(text: bestSerial ?? '');
    _modelController = TextEditingController(text: bestModel ?? '');
  }

  @override
  void dispose() {
    _serialController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _confirm() {
    final serial = _serialController.text.trim();
    final model = _modelController.text.trim();

    Navigator.of(context).pop(OcrReviewResult(
      serialNumber: serial.isNotEmpty ? serial : null,
      model: model.isNotEmpty ? model : null,
      isVerified: serial.isNotEmpty,
      imagePath: widget.imagePath,
    ));
  }

  void _markUnreadable() {
    Navigator.of(context).pop(OcrReviewResult(
      isVerified: false,
      missingReason: 'Sticker unreadable or missing',
      imagePath: widget.imagePath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review Label OCR',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.black12,
                  child: File(widget.imagePath).existsSync()
                      ? Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        )
                      : const Center(child: Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(height: 14),

              // Detected Candidates chips
              if (widget.candidates.isNotEmpty) ...[
                Text(
                  'Tap Detected Text to Fill:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.candidates.map((cand) {
                    final isSerial = cand.type == CandidateType.serial;
                    final isModel = cand.type == CandidateType.model;
                    return ActionChip(
                      avatar: Icon(
                        isSerial
                            ? Icons.verified_outlined
                            : (isModel ? Icons.laptop : Icons.tag),
                        size: 16,
                        color: isSerial ? Colors.green : Colors.blue,
                      ),
                      label: Text(
                        '${cand.value} (${cand.type.name})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isModel) {
                            _modelController.text = cand.value;
                          } else {
                            _serialController.text = cand.value;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No clear serial detected. You can type it manually below or mark as unreadable.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Serial Number Input Field
              TextField(
                controller: _serialController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Serial Number / Service Tag',
                  hintText: 'e.g. 7B3K9X2, 5CD1234XYZ',
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: _serialController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _serialController.clear()),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Ambiguity quick-fix chips (0 vs O, 1 vs I)
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Change O → 0', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _serialController.text =
                            _serialController.text.replaceAll('O', '0');
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Change I → 1', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _serialController.text =
                            _serialController.text.replaceAll('I', '1');
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Upper Case', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setState(() {
                        _serialController.text =
                            _serialController.text.toUpperCase();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Model Field
              TextField(
                controller: _modelController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Detected Model / Part No. (Optional)',
                  hintText: 'e.g. Inspiron 15 3511',
                  prefixIcon: const Icon(Icons.laptop),
                  suffixIcon: _modelController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _modelController.clear()),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Verified Info'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _markUnreadable,
                icon: const Icon(Icons.help_outline),
                label: const Text('Sticker Unreadable / Missing'),
              ),
            ],
          ),
        );
      },
    );
  }
}

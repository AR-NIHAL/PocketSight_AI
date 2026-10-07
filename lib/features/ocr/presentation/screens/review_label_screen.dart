import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ocr_candidate.dart';
import '../widgets/ocr_review_sheet.dart';

class ReviewLabelScreen extends StatefulWidget {
  final String imagePath;
  final List<OcrCandidate> candidates;

  const ReviewLabelScreen({
    super.key,
    required this.imagePath,
    required this.candidates,
  });

  @override
  State<ReviewLabelScreen> createState() => _ReviewLabelScreenState();
}

class _ReviewLabelScreenState extends State<ReviewLabelScreen> {
  late TextEditingController _serialController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
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

  void _retakePhoto() {
    Navigator.of(context).pop(OcrReviewResult(
      isVerified: false,
      retakePhoto: true,
      imagePath: widget.imagePath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Review label'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Captured Sticker Image Preview
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: File(widget.imagePath).existsSync()
                          ? Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Amber Warning Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check the text before saving',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Serial Number Field (with pencil edit icon)
                  _buildFieldLabel('Serial number'),
                  TextFormField(
                    controller: _serialController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. 7B3K9X2',
                      suffixIcon: _serialController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _serialController.clear()),
                            )
                          : const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Model Field (with pencil edit icon)
                  _buildFieldLabel('Model'),
                  TextFormField(
                    controller: _modelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. DemoBook 14',
                      suffixIcon: _modelController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _modelController.clear()),
                            )
                          : const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Helper note
                  const Text(
                    'Correct any characters that were read incorrectly.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Ambiguity Fixers / Candidate suggestions
                  if (widget.candidates.isNotEmpty) ...[
                    const Text(
                      'Detected candidates:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.candidates.map((cand) {
                        final isSerial = cand.type == CandidateType.serial;
                        return ActionChip(
                          avatar: Icon(
                            isSerial ? Icons.verified_outlined : Icons.laptop,
                            size: 15,
                            color: isSerial ? AppTheme.primaryTeal : const Color(0xFF2563EB),
                          ),
                          label: Text(
                            '${cand.value} (${cand.type.name})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              if (cand.type == CandidateType.model) {
                                _modelController.text = cand.value;
                              } else {
                                _serialController.text = cand.value;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Common OCR fix chips (O vs 0, I vs 1)
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
                        label: const Text('UPPERCASE', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _serialController.text =
                                _serialController.text.toUpperCase();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Action Buttons (Retake Photo & Confirm Details)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Retake photo'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _confirm,
                      child: const Text(
                        'Confirm details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}

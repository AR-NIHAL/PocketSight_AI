import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ticket_number_generator.dart';
import '../../../ocr/presentation/screens/review_label_screen.dart';
import '../../../ocr/presentation/screens/sticker_camera_screen.dart';
import '../../../ocr/presentation/widgets/ocr_review_sheet.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/intake_details.dart';
import '../../domain/entities/repair_ticket.dart';
import '../../domain/entities/ticket_status.dart';
import '../../domain/entities/work_log_entry.dart';
import '../providers/ticket_providers.dart';
import 'no_serial_screen.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();

  // Device controllers
  String _selectedBrand = 'Dell';
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _specsController = TextEditingController();
  bool _isSerialVerified = false;
  bool _hasMissingSerial = false;
  String _missingReason = 'Sticker missing';
  String? _stickerPhotoPath;
  bool _showManualSerial = false;

  // Complaint controller
  final _complaintController = TextEditingController();

  // Condition controller
  final _conditionController = TextEditingController();
  final List<String> _intakePhotos = [];

  // Accessories checklist (pill toggles matching Screen 02)
  final Map<String, bool> _accessories = {
    'Charger': true,
    'Bag': false,
    'Power Cable': false,
    'Mouse': false,
    'Loose RAM/SSD': false,
  };
  final _customAccessoriesController = TextEditingController();

  // Logistics
  final _estimatedCostController = TextEditingController();
  final _storageShelfController = TextEditingController();

  bool _isSubmitting = false;

  final List<String> _brands = [
    'Dell',
    'HP',
    'Lenovo',
    'Asus',
    'Acer',
    'Apple',
    'Samsung',
    'Toshiba',
    'MSI',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _specsController.dispose();
    _complaintController.dispose();
    _conditionController.dispose();
    _customAccessoriesController.dispose();
    _estimatedCostController.dispose();
    _storageShelfController.dispose();
    super.dispose();
  }

  Future<void> _scanStickerOcr() async {
    final cameraResult = await Navigator.of(context).push<StickerCameraResult>(
      MaterialPageRoute(builder: (_) => const StickerCameraScreen()),
    );

    if (cameraResult == null) return;

    if (cameraResult.enterManually) {
      setState(() => _showManualSerial = true);
      return;
    }

    if (cameraResult.imagePath == null) return;

    final imagePath = cameraResult.imagePath!;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Processing label with on-device OCR...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final ocrService = ref.read(mlkitOcrServiceProvider);
      final candidates = await ocrService.processImage(imagePath);

      if (!mounted) return;

      final result = await Navigator.of(context).push<OcrReviewResult>(
        MaterialPageRoute(
          builder: (_) => ReviewLabelScreen(
            imagePath: imagePath,
            candidates: candidates,
          ),
        ),
      );

      if (result != null) {
        if (result.retakePhoto) {
          _scanStickerOcr();
          return;
        }
        setState(() {
          _stickerPhotoPath = result.imagePath;
          if (result.isVerified && result.serialNumber != null) {
            _serialController.text = result.serialNumber!;
            _isSerialVerified = true;
            _hasMissingSerial = false;
          } else if (result.missingReason != null) {
            _hasMissingSerial = true;
            _missingReason = result.missingReason!;
            _serialController.clear();
            _isSerialVerified = false;
          }
          if (result.model != null && result.model!.isNotEmpty) {
            _modelController.text = result.model!;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR Error: $e')),
      );
    }
  }

  Future<void> _navigateToNoSerial() async {
    final repo = ref.read(ticketRepositoryProvider);
    final seq = await repo.getNextSequenceNumber();
    if (!mounted) return;

    final result = await Navigator.of(context).push<NoSerialResult>(
      MaterialPageRoute(
        builder: (_) => NoSerialNumberScreen(sequenceNumber: seq),
      ),
    );

    if (result != null) {
      setState(() {
        _hasMissingSerial = true;
        _serialController.text = result.deviceId;
        _missingReason = result.reason;
        _isSerialVerified = false;
        if (result.identifyingNote != null && result.identifyingNote!.isNotEmpty) {
          if (_conditionController.text.isNotEmpty) {
            _conditionController.text += ' | Note: ${result.identifyingNote}';
          } else {
            _conditionController.text = 'Note: ${result.identifyingNote}';
          }
        }
        if (result.photoPath != null) {
          _intakePhotos.add(result.photoPath!);
        }
      });
    }
  }

  Future<void> _addIntakePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _intakePhotos.add(picked.path);
      });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(ticketRepositoryProvider);
      final photoStorage = ref.read(photoStorageServiceProvider);
      final ticketId = const Uuid().v4();

      // Persist photos
      String? persistentStickerPath;
      if (_stickerPhotoPath != null) {
        persistentStickerPath = await photoStorage.savePhoto(
          ticketId: ticketId,
          sourcePath: _stickerPhotoPath!,
          customPrefix: 'sticker',
        );
      }

      final List<String> persistentPhotos = [];
      for (int i = 0; i < _intakePhotos.length; i++) {
        final path = await photoStorage.savePhoto(
          ticketId: ticketId,
          sourcePath: _intakePhotos[i],
          customPrefix: 'condition_$i',
        );
        persistentPhotos.add(path);
      }

      final seq = await repo.getNextSequenceNumber();
      final ticketNumber = TicketNumberGenerator.generate(sequenceNumber: seq);

      final customer = Customer(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone: _altPhoneController.text.trim().isNotEmpty
            ? _altPhoneController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      final device = Device(
        id: const Uuid().v4(),
        brand: _selectedBrand,
        model: _modelController.text.trim(),
        serialNumber: _hasMissingSerial ? null : _serialController.text.trim(),
        isSerialVerified: !_hasMissingSerial && _isSerialVerified,
        missingSerialReason: _hasMissingSerial ? _missingReason : null,
        specs: _specsController.text.trim().isNotEmpty
            ? _specsController.text.trim()
            : null,
      );

      final suppliedAccessoriesList = _accessories.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final intakeDetails = IntakeDetails(
        physicalCondition: _conditionController.text.trim(),
        suppliedAccessories: suppliedAccessoriesList,
        customAccessoriesNote: _customAccessoriesController.text.trim().isNotEmpty
            ? _customAccessoriesController.text.trim()
            : null,
        photoPaths: persistentPhotos,
        stickerPhotoPath: persistentStickerPath,
      );

      final estimatedCost = double.tryParse(_estimatedCostController.text.trim());

      final ticket = RepairTicket(
        id: ticketId,
        ticketNumber: ticketNumber,
        customer: customer,
        device: device,
        reportedIssue: _complaintController.text.trim(),
        intakeDetails: intakeDetails,
        status: TicketStatus.received,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workLogs: [
          WorkLogEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            note: 'Ticket created. Device received for diagnosis.',
            statusChange: TicketStatus.received,
          ),
        ],
        estimatedCost: estimatedCost,
        storageLocation: _storageShelfController.text.trim().isNotEmpty
            ? _storageShelfController.text.trim()
            : null,
      );

      await repo.saveTicket(ticket);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket ${ticket.shortTicketNumber} created successfully!'),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('New repair'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. Customer Section
                    _buildFieldLabel('Customer name'),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Tanvir Ahmed',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter customer name' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Phone'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 017XXXXXXXX',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 14),

                    // 2. Device Section (Model + Scan device label Card)
                    _buildFieldLabel('Model'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedBrand,
                            decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: _brands
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(
                                        b,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedBrand = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _modelController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'e.g. DemoBook 14',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter model' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // "Scan device label" Card (Teal border, camera icon, chevron)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _scanStickerOcr,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryTeal,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppTheme.primaryTeal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Scan device label',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _serialController.text.isNotEmpty
                                        ? (_hasMissingSerial
                                            ? 'Shop ID: ${_serialController.text}'
                                            : 'S/N: ${_serialController.text}${_isSerialVerified ? ' (Verified)' : ''}')
                                        : 'Read serial and model',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _serialController.text.isNotEmpty
                                          ? AppTheme.primaryTeal
                                          : AppTheme.textMuted,
                                      fontWeight: _serialController.text.isNotEmpty
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.primaryTeal,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // "No serial number" link & "Enter manually" toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _navigateToNoSerial,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'No serial number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _showManualSerial = !_showManualSerial);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showManualSerial ? 'Hide serial field' : 'Enter serial manually',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    if (_showManualSerial || _serialController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _serialController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: _hasMissingSerial ? 'Shop Device ID' : 'Serial / Service Tag',
                          hintText: 'e.g. 7B3K9X2',
                          prefixIcon: Icon(
                            _hasMissingSerial ? Icons.tag : Icons.qr_code_scanner,
                            size: 20,
                            color: AppTheme.primaryTeal,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSerialVerified)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                                ),
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _serialController.clear();
                                    _isSerialVerified = false;
                                    _hasMissingSerial = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 3. Complaint Section
                    _buildFieldLabel('Complaint'),
                    TextFormField(
                      controller: _complaintController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Describe the issue (e.g. No display, water damage)...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter reported complaint'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Accessories Section (Pill toggles)
                    _buildFieldLabel('Accessories'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _accessories.keys.map((accKey) {
                        final isSelected = _accessories[accKey] ?? false;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _accessories[accKey] = !isSelected;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryTeal : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  accKey,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 5. Condition Photos & Notes
                    OutlinedButton.icon(
                      onPressed: _addIntakePhoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text(
                        _intakePhotos.isEmpty
                            ? 'Add condition photo'
                            : 'Add another photo (${_intakePhotos.length})',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_intakePhotos.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _intakePhotos.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_intakePhotos[i]),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: InkWell(
                                    onTap: () => setState(() => _intakePhotos.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _conditionController,
                      decoration: const InputDecoration(
                        labelText: 'Observed condition (optional)',
                        hintText: 'e.g. Scratches on lid, minor hinge play',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Logistics (Collapsible / optional)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Logistics & Estimated Cost (Optional)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _estimatedCostController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Est. Cost (৳)',
                                    prefixText: '৳ ',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _storageShelfController,
                                  decoration: const InputDecoration(
                                    labelText: 'Shelf / Bin',
                                    hintText: 'e.g. Shelf B-3',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Bottom Full-width Continue Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
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

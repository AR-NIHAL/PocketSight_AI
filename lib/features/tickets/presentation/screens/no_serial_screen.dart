import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NoSerialResult {
  final String deviceId;
  final String reason;
  final String? identifyingNote;
  final String? photoPath;

  const NoSerialResult({
    required this.deviceId,
    required this.reason,
    this.identifyingNote,
    this.photoPath,
  });
}

class NoSerialNumberScreen extends StatefulWidget {
  final int sequenceNumber;

  const NoSerialNumberScreen({
    super.key,
    required this.sequenceNumber,
  });

  @override
  State<NoSerialNumberScreen> createState() => _NoSerialNumberScreenState();
}

class _NoSerialNumberScreenState extends State<NoSerialNumberScreen> {
  String _selectedReason = 'Sticker missing';
  final _identifyingNoteController = TextEditingController();
  String? _devicePhotoPath;

  late String _generatedDeviceId;

  final List<String> _reasons = [
    'Sticker missing',
    'Sticker unreadable / worn out',
    'Assembled / No serial plate',
    'Customer declined removal',
  ];

  @override
  void initState() {
    super.initState();
    // Generates a shop device ID like DEV-0042 matching Screen 05
    _generatedDeviceId = 'DEV-${widget.sequenceNumber.toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _identifyingNoteController.dispose();
    super.dispose();
  }

  Future<void> _addDevicePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _devicePhotoPath = picked.path);
    }
  }

  void _submit() {
    Navigator.of(context).pop(NoSerialResult(
      deviceId: _generatedDeviceId,
      reason: _selectedReason,
      identifyingNote: _identifyingNoteController.text.trim().isNotEmpty
          ? _identifyingNoteController.text.trim()
          : null,
      photoPath: _devicePhotoPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('No serial number'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Blue Info Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Soft Blue
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You can still create a repair ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Use a shop device ID to track this device in your workshop.',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Reason Dropdown
          const Text(
            'Reason',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedReason = val);
            },
          ),
          const SizedBox(height: 20),

          // 3. Shop Device ID Card (Yellow/Cream Tag Card)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3), // Soft cream/yellow
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE047)),
            ),
            child: Column(
              children: [
                const Text(
                  'Shop Device ID',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF854D0E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _generatedDeviceId,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Write this ID on a tag attached to the device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Add Device Photo Outlined Button
          OutlinedButton.icon(
            onPressed: _addDevicePhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(_devicePhotoPath != null ? 'Change device photo' : 'Add device photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          if (_devicePhotoPath != null) ...[
            const SizedBox(height: 10),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_devicePhotoPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 5. Identifying note (optional)
          const Text(
            'Identifying note (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _identifyingNoteController,
            decoration: const InputDecoration(
              hintText: 'e.g. Scratch on left edge, missing footpad',
            ),
          ),
          const SizedBox(height: 32),

          // 6. Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D5C56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submit,
              child: const Text(
                'Continue with Device ID',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

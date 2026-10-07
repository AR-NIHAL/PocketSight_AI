import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/shop_profile.dart';
import '../providers/ticket_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _shopNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _termsController;

  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(shopProfileProvider);
    _shopNameController = TextEditingController(text: profile.shopName);
    _phoneController = TextEditingController(text: profile.phone);
    _addressController = TextEditingController(text: profile.address);
    _termsController = TextEditingController(text: profile.termsNote);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final updated = ShopProfile(
      shopName: _shopNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      termsNote: _termsController.text.trim(),
    );
    await ref.read(shopProfileProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop profile saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup archive created and shared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    setState(() => _isRestoring = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final restoreResult = await backupService.restoreBackup(path);

      if (!mounted) return;
      if (restoreResult.success) {
        // Refresh profile text fields
        final p = ref.read(shopProfileProvider);
        _shopNameController.text = p.shopName;
        _phoneController.text = p.phone;
        _addressController.text = p.address;
        _termsController.text = p.termsNote;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Successful!'),
            content: Text(
              'Restored ${restoreResult.ticketsCount} tickets and ${restoreResult.photosCount} photos from backup archive.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restoreResult.errorMessage ?? 'Restore failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Shop Profile
          Text(
            'Shop Profile (Displayed on Receipts)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shopNameController,
            decoration: const InputDecoration(
              labelText: 'Shop Name',
              prefixIcon: Icon(Icons.store),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Shop Phone',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Shop Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _termsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Receipt Terms Note / Disclaimer',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text('Save Shop Profile'),
          ),
          const Divider(height: 36),

          // 2. Data Backup & Restore
          Text(
            'Local Data Durability & Backup',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Export all repair tickets, work logs, and device photos into a single portable ZIP archive to protect against phone loss or reinstallation.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.cloud_upload_outlined, color: Colors.white),
                    ),
                    title: const Text('Export Complete Backup'),
                    subtitle: const Text('Package tickets + all photos to ZIP'),
                    trailing: _isBackingUp
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton(
                            onPressed: _exportBackup,
                            child: const Text('Export'),
                          ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.restore, color: Colors.white),
                    ),
                    title: const Text('Restore from Backup File'),
                    subtitle: const Text('Load tickets and images from ZIP'),
                    trailing: _isRestoring
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton(
                            onPressed: _restoreBackup,
                            child: const Text('Restore'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

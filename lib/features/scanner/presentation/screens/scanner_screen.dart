import 'package:flutter/material.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PocketSight')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.center_focus_strong, size: 64),
            SizedBox(height: 16),
            Text('Live Scanner'),
            SizedBox(height: 8),
            Text('Camera + ML pipeline lands in Phase 2'),
          ],
        ),
      ),
    );
  }
}

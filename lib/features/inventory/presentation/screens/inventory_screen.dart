import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64),
            SizedBox(height: 16),
            Text('Offline Inventory'),
            SizedBox(height: 8),
            Text('Gallery + JSON backup lands in Phase 4'),
          ],
        ),
      ),
    );
  }
}

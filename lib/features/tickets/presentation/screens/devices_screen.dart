import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ticket_providers.dart';
import 'device_history_screen.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workshop Devices'),
            Text(
              'Hardware inventory & device history',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search device model or serial number…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              data: (tickets) {
                // Group unique devices by serial number or ID
                final Map<String, dynamic> uniqueDevices = {};
                for (final t in tickets) {
                  final key = t.device.serialNumber != null && t.device.serialNumber!.isNotEmpty
                      ? t.device.serialNumber!
                      : t.device.id;
                  if (!uniqueDevices.containsKey(key)) {
                    uniqueDevices[key] = {
                      'device': t.device,
                      'ticketsCount': 1,
                      'latestCustomer': t.customer.name,
                    };
                  } else {
                    uniqueDevices[key]['ticketsCount'] =
                        (uniqueDevices[key]['ticketsCount'] as int) + 1;
                  }
                }

                var list = uniqueDevices.values.toList();
                if (_searchQuery.isNotEmpty) {
                  list = list.where((item) {
                    final d = item['device'];
                    final matchModel = d.displayName.toLowerCase().contains(_searchQuery);
                    final matchSerial = (d.serialNumber ?? '').toLowerCase().contains(_searchQuery);
                    return matchModel || matchSerial;
                  }).toList();
                }

                if (list.isEmpty) {
                  return const Center(
                    child: Text('No devices found in workshop.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = list[i];
                    final d = item['device'];
                    final count = item['ticketsCount'] as int;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2FE),
                          child: Icon(Icons.laptop, color: Color(0xFF0369A1)),
                        ),
                        title: Text(
                          d.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'S/N: ${d.displaySerial} • $count repair(s)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (d.serialNumber != null && d.serialNumber!.isNotEmpty) {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => DeviceHistoryScreen(
                                serialNumber: d.serialNumber!,
                                deviceDisplayName: d.displayName,
                              ),
                            ));
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'core/presentation/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/tickets/data/repositories/hive_ticket_repository.dart';
import 'features/tickets/presentation/providers/ticket_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final ticketRepository = HiveTicketRepository();
  await ticketRepository.init();

  runApp(
    ProviderScope(
      overrides: [
        ticketRepositoryProvider.overrideWithValue(ticketRepository),
      ],
      child: const RepairIntakeApp(),
    ),
  );
}

class RepairIntakeApp extends StatelessWidget {
  const RepairIntakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Repair Intake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

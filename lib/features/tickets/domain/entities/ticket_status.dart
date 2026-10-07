import 'package:flutter/material.dart';

enum TicketStatus {
  received,
  inProgress,
  ready,
  delivered,
  closedWithoutRepair;

  String get displayName {
    switch (this) {
      case TicketStatus.received:
        return 'Received';
      case TicketStatus.inProgress:
        return 'In progress';
      case TicketStatus.ready:
        return 'Ready';
      case TicketStatus.delivered:
        return 'Delivered';
      case TicketStatus.closedWithoutRepair:
        return 'Closed';
    }
  }

  Color get color {
    return textColor;
  }

  Color get backgroundColor {
    switch (this) {
      case TicketStatus.ready:
        return const Color(0xFFDCFCE7); // Soft light green
      case TicketStatus.inProgress:
        return const Color(0xFFE0F2FE); // Soft light blue
      case TicketStatus.received:
        return const Color(0xFFFEF3C7); // Soft light amber
      case TicketStatus.delivered:
        return const Color(0xFFD1FAE5); // Soft light emerald
      case TicketStatus.closedWithoutRepair:
        return const Color(0xFFFEE2E2); // Soft light red
    }
  }

  Color get textColor {
    switch (this) {
      case TicketStatus.ready:
        return const Color(0xFF15803D); // Forest green
      case TicketStatus.inProgress:
        return const Color(0xFF0369A1); // Deep sky blue
      case TicketStatus.received:
        return const Color(0xFFB45309); // Dark amber
      case TicketStatus.delivered:
        return const Color(0xFF047857); // Deep emerald
      case TicketStatus.closedWithoutRepair:
        return const Color(0xFF991B1B); // Crimson red
    }
  }

  IconData get icon {
    switch (this) {
      case TicketStatus.received:
        return Icons.inbox_outlined;
      case TicketStatus.inProgress:
        return Icons.build_circle_outlined;
      case TicketStatus.ready:
        return Icons.check_circle_outline;
      case TicketStatus.delivered:
        return Icons.task_alt;
      case TicketStatus.closedWithoutRepair:
        return Icons.cancel_outlined;
    }
  }
}

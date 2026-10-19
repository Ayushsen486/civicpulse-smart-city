import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Civic Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color secondary = Color(0xFF0D9488); // Teal Green
  static const Color secondaryLight = Color(0xFF14B8A6);

  // Status Colors
  static const Color statusReported = Color(0xFF2563EB);
  static const Color statusAcknowledged = Color(0xFF7C3AED);
  static const Color statusAssigned = Color(0xFFD97706);
  static const Color statusInProgress = Color(0xFFEA580C);
  static const Color statusResolved = Color(0xFF059669);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusReopened = Color(0xFFDC2626);

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityCritical = Color(0xFFDC2626);

  // Neutral Colors (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Colors (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Accents & Badges
  static const Color cardShadow = Color(0x0A000000);
  static const Color aiBadge = Color(0xFF6366F1); // Indigo AI badge
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0xFF334155);

  // Helper method for resolving status colors consistently
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return statusReported;
      case 'ACKNOWLEDGED':
        return statusAcknowledged;
      case 'ASSIGNED':
        return statusAssigned;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'RESOLVED':
        return statusResolved;
      case 'CLOSED':
        return statusClosed;
      case 'REOPENED':
        return statusReopened;
      default:
        return primary;
    }
  }

  // Helper method for resolving priority colors consistently
  static Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return priorityCritical;
      case 'HIGH':
        return priorityHigh;
      case 'MEDIUM':
        return priorityMedium;
      case 'LOW':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }
}

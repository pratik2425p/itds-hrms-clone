import 'package:flutter/material.dart';

class AppColors {
  // LogiLead Enterprise Modern Brand Colors
  static const Color primary = Color(0xFF2563EB); // Modern Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Royal Blue
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Blue 50
  static const Color accent = Color(0xFF0EA5E9); // Modern Sky Cyan
  static const Color accentTeal = Color(0xFF14B8A6); // Modern Emerald Teal

  // Sidebar & Dark Surfaces
  static const Color sidebarBg = Color(0xFF0A1329); // Deep Midnight Enterprise Navy
  static const Color sidebarSurface = Color(0xFF112240); // Slightly lighter navy container
  static const Color sidebarBorder = Color(0xFF1E2D4A); // Subtle navy border
  static const Color sidebarTextActive = Colors.white;
  static const Color sidebarTextMuted = Color(0xFF94A3B8); // Slate 400

  // Canvas & Surfaces
  static const Color scaffoldBg = Color(0xFFF8FAFC); // Clean Slate 50
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200

  // Backward compatibility mappings for legacy references
  static const Color logiBlue = primary;
  static const Color logiNavy = sidebarBg;
  static const Color logiDark = Color(0xFF070D1E);
  static const Color logiCyan = accent;
  static const Color logiLightBlue = primaryLight;

  static const Color primaryBlue = primary;
  static const Color primaryOrange = primary;
  static const Color darkOrange = primaryDark;
  static const Color lightOrange = primaryLight;
  static const Color accentOrange = accent;

  // Header and Banner
  static const Color bannerBgStart = Colors.white;
  static const Color bannerBgMid = Colors.white;
  static const Color bannerBgEnd = Colors.white;

  // Quick Action Cards
  static const Color requestLeaveCard = Color(0xFFEFF6FF);
  static const Color regularizationCard = Color(0xFFF0FDF4);
  static const Color manageProfileCard = Color(0xFFFAF5FF);

  // Status Indicators
  static const Color presentGreen = Color(0xFF10B981); // Emerald 500
  static const Color absentRed = Color(0xFFEF4444); // Red 500
  static const Color weeklyOffOrange = Color(0xFFF59E0B); // Amber 500
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color leavesBlue = Color(0xFF3B82F6); // Blue 500
  static const Color holidaysPurple = Color(0xFF8B5CF6); // Purple 500
  static const Color pendingAmber = Color(0xFFF59E0B); // Amber 500

  // Typography
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
}

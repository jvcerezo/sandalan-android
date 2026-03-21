/// Color tokens matching the web app's design system.

import 'package:flutter/material.dart';

/// Life stage colors (used for journey map, stage cards, etc.)
class StageColors {
  static const blue = Color(0xFF3B82F6);       // Unang Hakbang
  static const emerald = Color(0xFF10B981);    // Pundasyon
  static const violet = Color(0xFF8B5CF6);     // Tahanan
  static const amber = Color(0xFFF59E0B);      // Tugatog
  static const rose = Color(0xFFF43F5E);       // Paghahanda
  static const yellow = Color(0xFFEAB308);     // Gintong Taon

  static const List<Color> all = [blue, emerald, violet, amber, rose, yellow];

  static Color forIndex(int index) => all[index % all.length];
}

/// Semantic colors for categories and status.
class AppColors {
  // Category colors
  static const income = Color(0xFF22C55E);    // green-500
  static const expense = Color(0xFF64748B);   // slate-500 (neutral, not red)
  static const transfer = Color(0xFF6366F1);  // indigo-500

  // Status colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Tool icon background colors
  static const toolBlue = Color(0xFF3B82F6);
  static const toolOrange = Color(0xFFF97316);
  static const toolGreen = Color(0xFF22C55E);
  static const toolRed = Color(0xFFEF4444);
  static const toolIndigo = Color(0xFF6366F1);
  static const toolTeal = Color(0xFF14B8A6);
  static const toolAmber = Color(0xFFF59E0B);
  static const toolEmerald = Color(0xFF10B981);
  static const toolPink = Color(0xFFEC4899);
  static const toolPurple = Color(0xFFA855F7);

  // Contribution type colors (matching web)
  static const sss = Color(0xFF3B82F6);       // blue
  static const philhealth = Color(0xFF22C55E); // green
  static const pagibig = Color(0xFFF97316);    // orange
}

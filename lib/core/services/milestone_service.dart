import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tier determines the celebration UI for a milestone.
enum MilestoneTier {
  /// Overlay + confetti animation
  a,

  /// SnackBar toast
  b,

  /// Silent (no UI, just record)
  c,
}

/// Category for grouping in the achievements screen.
enum MilestoneCategory {
  streaks,
  transactions,
  goalsSavings,
  adultingJourney,
}

/// A milestone definition.
class Milestone {
  final String id;
  final String title;
  final String? description;
  final IconData icon;
  final MilestoneCategory category;
  final MilestoneTier tier;

  const Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    required this.category,
    required this.tier,
  });
}

/// Service for tracking and triggering milestone celebrations.
class MilestoneService {
  static const _prefsKey = 'earned_milestones';
  static const _lastViewedKey = 'milestones_last_viewed';

  /// All milestone definitions.
  static final List<Milestone> allMilestones = [
    // ── Tier A (overlay + confetti) ───────────────────────────────────────
    const Milestone(
      id: 'first_transaction',
      title: 'First Transaction',
      description: 'Simula ng magandang ugali!',
      icon: LucideIcons.sparkles,
      category: MilestoneCategory.transactions,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Isang linggo!',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'streak_30',
      title: '30-Day Streak',
      description: 'Isang buwan! Consistent ka!',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'streak_100',
      title: '100-Day Streak',
      description: 'Idol ka na namin!',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'first_goal_funded',
      title: 'Goal Reached',
      description: 'Congrats! Target achieved!',
      icon: LucideIcons.trophy,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'first_debt_paid',
      title: 'Debt Free',
      description: 'Isa pang utang, tapos na!',
      icon: LucideIcons.checkCircle2,
      category: MilestoneCategory.adultingJourney,
      tier: MilestoneTier.a,
    ),
    const Milestone(
      id: 'stage_complete',
      title: 'Stage Complete',
      description: 'Ready for the next level!',
      icon: LucideIcons.graduationCap,
      category: MilestoneCategory.adultingJourney,
      tier: MilestoneTier.a,
    ),

    // ── Tier B (toast) ────────────────────────────────────────────────────
    const Milestone(
      id: 'streak_14',
      title: '14-Day Streak',
      description: 'Dalawang linggo na!',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'streak_60',
      title: '60-Day Streak',
      description: 'Two months strong!',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'streak_365',
      title: 'One Year!',
      description: 'Isang taon! Legend.',
      icon: LucideIcons.crown,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'tx_10',
      title: '10 Transactions',
      description: 'Getting into the habit!',
      icon: LucideIcons.arrowLeftRight,
      category: MilestoneCategory.transactions,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'tx_50',
      title: '50 Transactions',
      description: 'Tracking master!',
      icon: LucideIcons.arrowLeftRight,
      category: MilestoneCategory.transactions,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'first_insurance',
      title: 'First Policy',
      description: 'Protected!',
      icon: LucideIcons.shield,
      category: MilestoneCategory.adultingJourney,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'emergency_1mo',
      title: '1-Month Emergency Fund',
      description: 'One month covered!',
      icon: LucideIcons.shieldCheck,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'emergency_3mo',
      title: '3-Month Emergency Fund',
      description: 'Three months safe!',
      icon: LucideIcons.shieldCheck,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'emergency_6mo',
      title: '6-Month Emergency Fund',
      description: 'Fully protected!',
      icon: LucideIcons.shieldCheck,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'all_govt_ids',
      title: 'All Government IDs',
      description: 'Fully registered Filipino adult!',
      icon: LucideIcons.badgeCheck,
      category: MilestoneCategory.adultingJourney,
      tier: MilestoneTier.b,
    ),
    const Milestone(
      id: 'first_contribution',
      title: 'First Contribution Paid',
      description: 'Adulting level up!',
      icon: LucideIcons.landmark,
      category: MilestoneCategory.adultingJourney,
      tier: MilestoneTier.b,
    ),

    // ── Tier C (silent) ───────────────────────────────────────────────────
    const Milestone(
      id: 'streak_3',
      title: '3-Day Streak',
      icon: LucideIcons.flame,
      category: MilestoneCategory.streaks,
      tier: MilestoneTier.c,
    ),
    const Milestone(
      id: 'tx_100',
      title: '100 Transactions',
      icon: LucideIcons.arrowLeftRight,
      category: MilestoneCategory.transactions,
      tier: MilestoneTier.c,
    ),
    const Milestone(
      id: 'tx_200',
      title: '200 Transactions',
      icon: LucideIcons.arrowLeftRight,
      category: MilestoneCategory.transactions,
      tier: MilestoneTier.c,
    ),
    const Milestone(
      id: 'goal_2',
      title: '2 Goals Reached',
      icon: LucideIcons.trophy,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.c,
    ),
    const Milestone(
      id: 'goal_3',
      title: '3 Goals Reached',
      icon: LucideIcons.trophy,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.c,
    ),
    const Milestone(
      id: 'budget_month_clean',
      title: 'Clean Budget Month',
      icon: LucideIcons.pieChart,
      category: MilestoneCategory.goalsSavings,
      tier: MilestoneTier.c,
    ),
  ];

  /// Check and trigger a milestone. Returns the milestone if newly earned, null otherwise.
  static Future<Milestone?> checkAndTrigger(String milestoneId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final earned = raw != null
        ? Map<String, String>.from(jsonDecode(raw) as Map)
        : <String, String>{};

    if (earned.containsKey(milestoneId)) return null;

    // Mark as earned
    earned[milestoneId] = DateTime.now().toIso8601String();
    await prefs.setString(_prefsKey, jsonEncode(earned));

    // Find the milestone definition
    try {
      return allMilestones.firstWhere((m) => m.id == milestoneId);
    } catch (_) {
      return null;
    }
  }

  /// Get all earned milestones as a map of milestone_id -> earned_date.
  static Future<Map<String, String>> getEarnedMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  /// Get all milestone definitions.
  static List<Milestone> getAllMilestones() => allMilestones;

  /// Whether there are new milestones earned since last time the achievements screen was viewed.
  static Future<bool> hasNewMilestones() async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewed = prefs.getString(_lastViewedKey);
    final earned = await getEarnedMilestones();

    if (earned.isEmpty) return false;
    if (lastViewed == null) return earned.isNotEmpty;

    final lastViewedDate = DateTime.parse(lastViewed);
    return earned.values.any((dateStr) {
      final earnedDate = DateTime.parse(dateStr);
      return earnedDate.isAfter(lastViewedDate);
    });
  }

  /// Mark that the user has viewed the achievements screen.
  static Future<void> markViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastViewedKey, DateTime.now().toIso8601String());
  }

  /// Get the category display name.
  static String categoryName(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.streaks:
        return 'Streaks';
      case MilestoneCategory.transactions:
        return 'Transactions';
      case MilestoneCategory.goalsSavings:
        return 'Goals & Savings';
      case MilestoneCategory.adultingJourney:
        return 'Adulting Journey';
    }
  }
}

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
  financial,
  debtFreedom,
  streaks,
  transactions,
  goalsSavings,
  adultingJourney,
  toolsFeatures,
  special,
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

    // ── FINANCIAL MILESTONES ────────────────────────────────────────────
    const Milestone(id: 'first_budget', title: 'First Budget', description: 'Simula ng disiplina!',
        icon: LucideIcons.pieChart, category: MilestoneCategory.financial, tier: MilestoneTier.b),
    const Milestone(id: 'budget_3_months', title: 'Budget Streak', description: '3 consecutive clean budget months!',
        icon: LucideIcons.pieChart, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'first_savings_goal', title: 'First Savings Goal', description: 'Nag-set ng target!',
        icon: LucideIcons.target, category: MilestoneCategory.financial, tier: MilestoneTier.b),
    const Milestone(id: 'saved_1k', title: '₱1K Saved', description: 'Unang libo!',
        icon: LucideIcons.piggyBank, category: MilestoneCategory.financial, tier: MilestoneTier.b),
    const Milestone(id: 'saved_5k', title: '₱5K Saved', description: 'Lima libo na!',
        icon: LucideIcons.piggyBank, category: MilestoneCategory.financial, tier: MilestoneTier.b),
    const Milestone(id: 'saved_10k', title: '₱10K Saved', description: 'Sampung libo! Keep going!',
        icon: LucideIcons.piggyBank, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'saved_50k', title: '₱50K Saved', description: 'Kalahating daan na libo!',
        icon: LucideIcons.piggyBank, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'saved_100k', title: 'Six Figures', description: '₱100,000! Ang galing mo!',
        icon: LucideIcons.gem, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'saved_500k', title: 'Half Millionaire', description: 'Kalahating milyon! Idol!',
        icon: LucideIcons.gem, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'saved_1m', title: 'Millionaire', description: '₱1,000,000! Legend status!',
        icon: LucideIcons.crown, category: MilestoneCategory.financial, tier: MilestoneTier.a),
    const Milestone(id: 'positive_net_worth', title: 'Positive Net Worth', description: 'Assets > Debts!',
        icon: LucideIcons.trendingUp, category: MilestoneCategory.financial, tier: MilestoneTier.a),

    // ── DEBT FREEDOM ────────────────────────────────────────────────────
    const Milestone(id: 'first_debt_payment', title: 'First Debt Payment', description: 'Unang bayad sa utang!',
        icon: LucideIcons.creditCard, category: MilestoneCategory.debtFreedom, tier: MilestoneTier.b),
    const Milestone(id: 'debt_50_percent', title: 'Halfway There', description: '50% of a debt paid off!',
        icon: LucideIcons.creditCard, category: MilestoneCategory.debtFreedom, tier: MilestoneTier.b),
    const Milestone(id: 'all_debts_paid', title: 'Completely Debt Free', description: 'WALANG UTANG!',
        icon: LucideIcons.partyPopper, category: MilestoneCategory.debtFreedom, tier: MilestoneTier.a),
    const Milestone(id: 'credit_card_paid', title: 'Credit Card Clear', description: 'Full payment, no interest!',
        icon: LucideIcons.creditCard, category: MilestoneCategory.debtFreedom, tier: MilestoneTier.b),

    // ── MORE STREAKS ────────────────────────────────────────────────────
    const Milestone(id: 'streak_90', title: 'Quarterly Champion', description: '90 days! Tatlong buwan!',
        icon: LucideIcons.flame, category: MilestoneCategory.streaks, tier: MilestoneTier.a),
    const Milestone(id: 'streak_180', title: 'Half Year Hero', description: '180 days! Kalahating taon!',
        icon: LucideIcons.flame, category: MilestoneCategory.streaks, tier: MilestoneTier.a),

    // ── MORE TRANSACTIONS ───────────────────────────────────────────────
    const Milestone(id: 'tx_25', title: '25 Transactions', description: 'Building the habit!',
        icon: LucideIcons.arrowLeftRight, category: MilestoneCategory.transactions, tier: MilestoneTier.c),
    const Milestone(id: 'tx_250', title: 'Quarter Thousand', description: '250 transactions!',
        icon: LucideIcons.arrowLeftRight, category: MilestoneCategory.transactions, tier: MilestoneTier.b),
    const Milestone(id: 'tx_500', title: 'Half Thousand', description: '500 transactions tracked!',
        icon: LucideIcons.arrowLeftRight, category: MilestoneCategory.transactions, tier: MilestoneTier.a),
    const Milestone(id: 'tx_1000', title: 'Transaction Master', description: '1000 transactions! Ang sipag!',
        icon: LucideIcons.crown, category: MilestoneCategory.transactions, tier: MilestoneTier.a),

    // ── ADULTING JOURNEY ────────────────────────────────────────────────
    const Milestone(id: 'first_guide_read', title: 'First Guide', description: 'Nagbasa ka! Good start!',
        icon: LucideIcons.bookOpen, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.b),
    const Milestone(id: 'guides_5', title: 'Bookworm', description: '5 guides read!',
        icon: LucideIcons.bookOpen, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.b),
    const Milestone(id: 'guides_10', title: 'Knowledge Seeker', description: '10 guides nabasa mo na!',
        icon: LucideIcons.bookOpen, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.a),
    const Milestone(id: 'guides_all', title: 'Scholar', description: 'Read ALL guides!',
        icon: LucideIcons.graduationCap, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.a),
    const Milestone(id: 'first_checklist', title: 'First Checklist Done', description: 'Natapos mo!',
        icon: LucideIcons.checkSquare, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.b),
    const Milestone(id: 'checklist_5', title: 'Getting Things Done', description: '5 checklist items!',
        icon: LucideIcons.checkSquare, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.b),
    const Milestone(id: 'checklist_10', title: 'Adulting Pro', description: '10 items completed!',
        icon: LucideIcons.checkSquare, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.a),
    const Milestone(id: 'all_stages', title: 'Fully Adulted', description: 'Completed ALL stages!',
        icon: LucideIcons.crown, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.a),
    const Milestone(id: 'first_govt_id', title: 'First Government ID', description: 'Welcome to adulting!',
        icon: LucideIcons.badgeCheck, category: MilestoneCategory.adultingJourney, tier: MilestoneTier.b),

    // ── TOOLS & FEATURES ────────────────────────────────────────────────
    const Milestone(id: 'first_scan', title: 'First Receipt Scan', description: 'High-tech ka na!',
        icon: LucideIcons.scanLine, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.b),
    const Milestone(id: 'scans_10', title: 'Scanner Pro', description: '10 receipts scanned!',
        icon: LucideIcons.scanLine, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.b),
    const Milestone(id: 'scans_50', title: 'OCR Master', description: '50 scans! Efficient!',
        icon: LucideIcons.scanLine, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.a),
    const Milestone(id: 'contributions_6mo', title: '6 Months Contributing', description: 'Half a year of contributions!',
        icon: LucideIcons.landmark, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.b),
    const Milestone(id: 'contributions_1yr', title: 'Full Year Contributor', description: '12 months straight!',
        icon: LucideIcons.landmark, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.a),
    const Milestone(id: 'first_bill_tracked', title: 'Bill Tracker', description: 'First bill added!',
        icon: LucideIcons.receipt, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.c),
    const Milestone(id: 'all_bills_paid', title: 'Bills Cleared', description: 'All bills paid this month!',
        icon: LucideIcons.receipt, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.b),
    const Milestone(id: 'first_tax_computed', title: 'Tax Filer', description: 'Computed your taxes!',
        icon: LucideIcons.fileText, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.c),
    const Milestone(id: 'first_report', title: 'First Report Card', description: 'Checked your monthly report!',
        icon: LucideIcons.barChart3, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.c),
    const Milestone(id: 'ai_chat_10', title: 'AI Buddy', description: '10 conversations with your assistant!',
        icon: LucideIcons.bot, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.b),
    const Milestone(id: 'ai_chat_50', title: 'Best Friends', description: '50 chats! BFF na kayo!',
        icon: LucideIcons.bot, category: MilestoneCategory.toolsFeatures, tier: MilestoneTier.a),

    // ── SPECIAL / FUN ───────────────────────────────────────────────────
    const Milestone(id: 'no_spend_day', title: 'No Spend Day', description: 'Zero gastos today!',
        icon: LucideIcons.ban, category: MilestoneCategory.special, tier: MilestoneTier.b),
    const Milestone(id: 'no_spend_week', title: 'No Spend Week', description: 'Buong linggo walang gastos!',
        icon: LucideIcons.ban, category: MilestoneCategory.special, tier: MilestoneTier.a),
    const Milestone(id: 'lowest_spending_month', title: 'Record Low', description: 'Lowest spending month ever!',
        icon: LucideIcons.trendingDown, category: MilestoneCategory.special, tier: MilestoneTier.a),
    const Milestone(id: 'highest_saving_month', title: 'Record Saver', description: 'Highest savings month ever!',
        icon: LucideIcons.trendingUp, category: MilestoneCategory.special, tier: MilestoneTier.a),
    const Milestone(id: 'friday_no_spend', title: 'TGIF Saver', description: 'Friday without spending!',
        icon: LucideIcons.partyPopper, category: MilestoneCategory.special, tier: MilestoneTier.c),
    const Milestone(id: 'early_bird', title: 'Early Bird', description: 'Logged expense before 7 AM',
        icon: LucideIcons.sunrise, category: MilestoneCategory.special, tier: MilestoneTier.c),
    const Milestone(id: 'night_owl', title: 'Night Owl', description: 'Logged expense after 11 PM',
        icon: LucideIcons.moon, category: MilestoneCategory.special, tier: MilestoneTier.c),
    const Milestone(id: 'weekend_warrior', title: 'Weekend Warrior', description: 'Tracked expenses all weekend',
        icon: LucideIcons.calendar, category: MilestoneCategory.special, tier: MilestoneTier.c),
    const Milestone(id: 'payday_saver', title: 'Payday Discipline', description: 'Saved on payday instead of splurging',
        icon: LucideIcons.wallet, category: MilestoneCategory.special, tier: MilestoneTier.b),
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
      case MilestoneCategory.financial:
        return 'Financial';
      case MilestoneCategory.debtFreedom:
        return 'Debt Freedom';
      case MilestoneCategory.streaks:
        return 'Streaks & Consistency';
      case MilestoneCategory.transactions:
        return 'Transactions';
      case MilestoneCategory.goalsSavings:
        return 'Goals & Savings';
      case MilestoneCategory.adultingJourney:
        return 'Adulting Journey';
      case MilestoneCategory.toolsFeatures:
        return 'Tools & Features';
      case MilestoneCategory.special:
        return 'Special';
    }
  }
}

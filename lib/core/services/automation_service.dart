import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/contribution_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/insurance_repository.dart';
import 'notification_service.dart';

/// Preference keys for automation toggles.
class AutomationKeys {
  static const autoContributions = 'auto_generate_contributions';
  static const autoBills = 'bills_reminders_enabled';
  static const autoDebts = 'debt_reminders_enabled';
  static const autoInsurance = 'insurance_reminders_enabled';
  static const pushEnabled = 'push_notifications';
  static const morningSummary = 'morning_summary';
}

/// Runs automation tasks at app startup based on user preferences stored in
/// SharedPreferences.
class AutomationService {
  AutomationService._();

  /// Call after Supabase is initialized and the user is authenticated.
  static Future<void> runOnAppStart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return; // not logged in, nothing to automate

    final prefs = await SharedPreferences.getInstance();
    final client = Supabase.instance.client;

    // ── Auto-generate monthly contributions ──────────────────────────────────
    if (prefs.getBool(AutomationKeys.autoContributions) ?? true) {
      await _autoGenerateContributions(client);
    }

    // ── Schedule bill reminders ──────────────────────────────────────────────
    if (prefs.getBool(AutomationKeys.autoBills) ?? true) {
      await _scheduleBillNotifications(client);
    }

    // ── Schedule debt reminders ──────────────────────────────────────────────
    if (prefs.getBool(AutomationKeys.autoDebts) ?? true) {
      await _scheduleDebtNotifications(client);
    }

    // ── Schedule insurance reminders ─────────────────────────────────────────
    if (prefs.getBool(AutomationKeys.autoInsurance) ?? true) {
      await _scheduleInsuranceNotifications(client);
    }
  }

  // ── Contributions ──────────────────────────────────────────────────────────

  /// If the current month's SSS / PhilHealth / Pag-IBIG entries don't exist
  /// yet, create them using the most recent salary on file.
  static Future<void> _autoGenerateContributions(SupabaseClient client) async {
    try {
      final repo = ContributionRepository(client);
      final now = DateTime.now();
      final currentPeriod =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final existing = await repo.getContributions(period: currentPeriod);
      final existingTypes = existing.map((c) => c.type).toSet();

      // Grab the most recent contribution to copy salary & employment type.
      final allContribs = await repo.getContributions();
      if (allContribs.isEmpty) return; // no history to base it on

      const types = ['sss', 'philhealth', 'pagibig'];
      for (final type in types) {
        if (existingTypes.contains(type)) continue;

        // Find the most recent entry for this specific type to get its shares.
        final latestOfType = allContribs.where((c) => c.type == type).toList();
        if (latestOfType.isEmpty) continue;

        final ref = latestOfType.first;
        await repo.createContribution(
          type: type,
          period: currentPeriod,
          monthlySalary: ref.monthlySalary,
          employeeShare: ref.employeeShare,
          employerShare: ref.employerShare,
          totalContribution: ref.totalContribution,
          employmentType: ref.employmentType,
          notes: 'Auto-generated from previous month',
        );
      }
    } catch (e) {
      debugPrint('AutomationService: contribution generation failed: $e');
    }
  }

  // ── Bill notifications ─────────────────────────────────────────────────────

  static Future<void> _scheduleBillNotifications(SupabaseClient client) async {
    try {
      final repo = BillRepository(client);
      final bills = await repo.getBills();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final bill in bills) {
        if (!bill.isActive || bill.dueDay == null) continue;

        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final dueDay = bill.dueDay!.clamp(1, lastDay);
        var dueDate = DateTime(now.year, now.month, dueDay);
        if (dueDate.isBefore(today)) {
          // Move to next month.
          final nextLastDay = DateTime(now.year, now.month + 2, 0).day;
          dueDate = DateTime(now.year, now.month + 1, dueDay.clamp(1, nextLastDay));
        }

        final daysUntil = dueDate.difference(today).inDays;
        if (daysUntil > 7) continue; // only within 7 days

        await NotificationService.instance.scheduleNotification(
          id: 'bill-${bill.id}'.hashCode,
          title: 'Bill due soon: ${bill.name}',
          body:
              '${bill.name} (PHP ${bill.amount.toStringAsFixed(2)}) is due in $daysUntil day${daysUntil == 1 ? '' : 's'}.',
          scheduledDate: dueDate,
        );
      }
    } catch (e) {
      debugPrint('AutomationService: bill notifications failed: $e');
    }
  }

  // ── Debt notifications ─────────────────────────────────────────────────────

  static Future<void> _scheduleDebtNotifications(SupabaseClient client) async {
    try {
      final repo = DebtRepository(client);
      final debts = await repo.getDebts();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final debt in debts) {
        if (debt.isPaidOff || debt.dueDay == null) continue;

        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final dueDay = debt.dueDay!.clamp(1, lastDay);
        var dueDate = DateTime(now.year, now.month, dueDay);
        if (dueDate.isBefore(today)) {
          final nextLastDay = DateTime(now.year, now.month + 2, 0).day;
          dueDate = DateTime(now.year, now.month + 1, dueDay.clamp(1, nextLastDay));
        }

        final daysUntil = dueDate.difference(today).inDays;
        if (daysUntil > 7) continue;

        await NotificationService.instance.scheduleNotification(
          id: 'debt-${debt.id}'.hashCode,
          title: 'Debt payment due: ${debt.name}',
          body:
              '${debt.name} (PHP ${debt.minimumPayment.toStringAsFixed(2)}) is due in $daysUntil day${daysUntil == 1 ? '' : 's'}.',
          scheduledDate: dueDate,
        );
      }
    } catch (e) {
      debugPrint('AutomationService: debt notifications failed: $e');
    }
  }

  // ── Insurance notifications ────────────────────────────────────────────────

  static Future<void> _scheduleInsuranceNotifications(
      SupabaseClient client) async {
    try {
      final repo = InsuranceRepository(client);
      final policies = await repo.getPolicies();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final policy in policies) {
        if (!policy.isActive || policy.renewalDate == null) continue;

        final renewal = DateTime.tryParse(policy.renewalDate!);
        if (renewal == null) continue;

        final daysUntil = renewal.difference(today).inDays;
        if (daysUntil < 0 || daysUntil > 7) continue;

        await NotificationService.instance.scheduleNotification(
          id: 'insurance-${policy.id}'.hashCode,
          title: 'Insurance premium due: ${policy.name}',
          body:
              '${policy.name} (PHP ${policy.premiumAmount.toStringAsFixed(2)}) is due in $daysUntil day${daysUntil == 1 ? '' : 's'}.',
          scheduledDate: renewal,
        );
      }
    } catch (e) {
      debugPrint('AutomationService: insurance notifications failed: $e');
    }
  }
}

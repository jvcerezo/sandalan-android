import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/tools/providers/tool_providers.dart';
import 'guest_mode_service.dart';

/// Service to export all user data as a JSON file.
class DataExportService {
  /// Collects all user data from local DB and exports to a JSON file.
  /// Returns the file path on success, or null on failure.
  static Future<String?> exportData(WidgetRef ref, BuildContext context) async {
    try {
      final db = AppDatabase.instance;
      final userId = _getUserId(ref);

      // Collect profile
      final profile = ref.read(profileProvider).valueOrNull;
      final profileData = profile != null
          ? {
              'full_name': profile.fullName,
              'email': profile.email,
              'avatar_url': profile.avatarUrl,
              'primary_currency': profile.primaryCurrency,
              'created_at': profile.createdAt,
            }
          : null;

      // Collect all data from local DB
      final accounts = await db.getAllAccounts(userId);
      final transactions = await db.getTransactions(userId);
      final budgets = await db.getAllBudgets(userId);
      final goals = await db.getGoals(userId);
      final debts = await db.getDebts(userId);
      final bills = await db.getBills(userId);
      final insurance = await db.getInsurancePolicies(userId);
      final contributions = await db.getContributions(userId);

      // Collect tax records (from Supabase, since there's no local table)
      List<Map<String, dynamic>> taxRecords = [];
      try {
        final taxes = await ref.read(taxRepositoryProvider).getTaxRecords();
        taxRecords = taxes.map((t) => t.toJson()).toList();
      } catch (_) {
        // Tax records may not be available offline
      }

      // Collect checklist progress from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final checklistDone = prefs.getStringList('checklist_done') ?? [];
      final checklistSkipped = prefs.getStringList('checklist_skipped') ?? [];
      final guidesRead = prefs.getStringList('guides_read') ?? [];

      // Build export object
      final exportData = {
        'export_info': {
          'app': 'Sandalan',
          'version': '0.1.0',
          'exported_at': DateTime.now().toUtc().toIso8601String(),
          'format': 'JSON',
        },
        'profile': profileData,
        'accounts': _cleanSyncStatus(accounts),
        'transactions': _cleanSyncStatus(transactions),
        'budgets': _cleanSyncStatus(budgets),
        'goals': _cleanSyncStatus(goals),
        'debts': _cleanSyncStatus(debts),
        'bills': _cleanSyncStatus(bills),
        'insurance_policies': _cleanSyncStatus(insurance),
        'contributions': _cleanSyncStatus(contributions),
        'tax_records': taxRecords,
        'checklist_progress': {
          'completed_items': checklistDone,
          'skipped_items': checklistSkipped,
          'guides_read': guidesRead,
        },
      };

      // Format JSON
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(exportData);

      // Save to downloads or documents directory
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'sandalan_export_$dateStr.json';

      Directory? dir;
      if (Platform.isAndroid) {
        // Try to use the Downloads directory
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Data export failed: $e');
      return null;
    }
  }

  static String _getUserId(WidgetRef ref) {
    try {
      final client = ref.read(supabaseClientProvider);
      final user = client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {}
    return GuestModeService.getGuestIdSync() ?? 'guest';
  }

  /// Remove sync_status from exported data since it's internal.
  static List<Map<String, dynamic>> _cleanSyncStatus(
      List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final clean = Map<String, dynamic>.from(row);
      clean.remove('sync_status');
      clean.remove('user_id');
      return clean;
    }).toList();
  }
}

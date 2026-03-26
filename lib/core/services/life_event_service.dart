import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Detects life events from user actions and suggests relevant guide content.
///
/// Events are detected based on:
/// - Transaction patterns (first salary, large housing payment)
/// - Goal names (wedding fund, baby fund)
/// - Account types (first investment account)
/// - User-triggered declarations ("I got a new job")
class LifeEventService {
  LifeEventService._();

  static const _dismissedKey = 'dismissed_life_events';

  /// Known life events with their triggers and guide recommendations.
  static const List<LifeEvent> _events = [
    LifeEvent(
      id: 'first_job',
      title: 'Got your first job?',
      subtitle: 'Set up your finances right from the start',
      icon: LucideIcons.briefcase,
      color: Color(0xFF3B82F6),
      stageSlug: 'unang-hakbang',
      triggers: ['first salary', 'new job', 'first day', 'onboarding', 'hired'],
    ),
    LifeEvent(
      id: 'moving_out',
      title: 'Moving out on your own?',
      subtitle: 'Budget for rent, utilities, and independent living',
      icon: LucideIcons.home,
      color: Color(0xFF8B5CF6),
      stageSlug: 'pundasyon',
      triggers: ['rent', 'moving out', 'apartment', 'condo', 'dorm'],
    ),
    LifeEvent(
      id: 'getting_married',
      title: 'Getting married?',
      subtitle: 'Plan your wedding budget and shared finances',
      icon: LucideIcons.heart,
      color: Color(0xFFEC4899),
      stageSlug: 'tahanan',
      triggers: ['wedding', 'kasal', 'engagement', 'married', 'prenup'],
    ),
    LifeEvent(
      id: 'having_baby',
      title: 'Expecting a baby?',
      subtitle: 'Prepare for the costs of parenthood',
      icon: LucideIcons.baby,
      color: Color(0xFFF59E0B),
      stageSlug: 'tahanan',
      triggers: ['baby', 'pregnant', 'maternity', 'paternity', 'newborn'],
    ),
    LifeEvent(
      id: 'buying_home',
      title: 'Buying a home?',
      subtitle: 'Navigate Pag-IBIG loans, down payments, and mortgages',
      icon: LucideIcons.building2,
      color: Color(0xFF10B981),
      stageSlug: 'tahanan',
      triggers: ['house', 'bahay', 'mortgage', 'pag-ibig housing', 'down payment'],
    ),
    LifeEvent(
      id: 'first_investment',
      title: 'Ready to invest?',
      subtitle: 'Learn about stocks, mutual funds, and growing your money',
      icon: LucideIcons.trendingUp,
      color: Color(0xFF6366F1),
      stageSlug: 'tugatog',
      triggers: ['invest', 'stocks', 'mutual fund', 'uitf', 'col financial'],
    ),
    LifeEvent(
      id: 'starting_business',
      title: 'Starting a business?',
      subtitle: 'Register your business and manage finances',
      icon: LucideIcons.store,
      color: Color(0xFFEF4444),
      stageSlug: 'tugatog',
      triggers: ['business', 'negosyo', 'freelance', 'side hustle', 'bir registration'],
    ),
    LifeEvent(
      id: 'planning_retirement',
      title: 'Thinking about retirement?',
      subtitle: 'Plan your golden years with SSS, GSIS, and investments',
      icon: LucideIcons.sunset,
      color: Color(0xFFEAB308),
      stageSlug: 'paghahanda',
      triggers: ['retirement', 'retire', 'pension', 'gsis', 'sss pension'],
    ),
  ];

  /// Check if any life event matches a description/goal name.
  /// Returns the first matching event that hasn't been dismissed.
  static Future<LifeEvent?> detectFromText(String text) async {
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    final dismissed = await _getDismissed();

    for (final event in _events) {
      if (dismissed.contains(event.id)) continue;
      for (final trigger in event.triggers) {
        if (lower.contains(trigger)) return event;
      }
    }
    return null;
  }

  /// Get all undismissed events (for the guide screen).
  static Future<List<LifeEvent>> getActiveEvents() async {
    final dismissed = await _getDismissed();
    return _events.where((e) => !dismissed.contains(e.id)).toList();
  }

  /// Dismiss a life event so it doesn't show again.
  static Future<void> dismiss(String eventId) async {
    final dismissed = await _getDismissed();
    dismissed.add(eventId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissedKey, dismissed.toList());
  }

  static Future<Set<String>> _getDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dismissedKey) ?? []).toSet();
  }
}

class LifeEvent {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String stageSlug; // Which guide stage to link to
  final List<String> triggers; // Keywords that detect this event

  const LifeEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.stageSlug,
    required this.triggers,
  });
}

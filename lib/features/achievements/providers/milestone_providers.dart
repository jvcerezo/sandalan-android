import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/milestone_service.dart';

/// Provider for the milestone service singleton operations.
final milestoneServiceProvider = Provider<MilestoneService>((ref) {
  return MilestoneService();
});

/// Provider for earned milestones map (milestone_id -> earned_date).
final earnedMilestonesProvider = FutureProvider<Map<String, String>>((ref) async {
  return MilestoneService.getEarnedMilestones();
});

/// Whether there are new milestones earned since last viewing the achievements screen.
final hasNewMilestonesProvider = FutureProvider<bool>((ref) async {
  return MilestoneService.hasNewMilestones();
});

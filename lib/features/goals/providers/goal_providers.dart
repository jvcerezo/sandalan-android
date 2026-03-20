import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../../data/models/goal.dart';
import '../../auth/providers/auth_provider.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(supabaseClientProvider));
});

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  return ref.read(goalRepositoryProvider).getGoals();
});

final goalsSummaryProvider = FutureProvider<GoalsSummary>((ref) async {
  return ref.read(goalRepositoryProvider).getGoalsSummary();
});

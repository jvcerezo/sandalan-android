import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> updateWidget({
    required String todaySpending,
    required int streakCount,
  }) async {
    await HomeWidget.saveWidgetData('today_spending', todaySpending);
    await HomeWidget.saveWidgetData('streak_count', streakCount);
    await HomeWidget.updateWidget(
      androidName: 'SandalanWidgetProvider',
    );
  }
}

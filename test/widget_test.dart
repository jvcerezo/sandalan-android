import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sandalan/app.dart';

void main() {
  testWidgets('App renders with bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SandalanApp(),
      ),
    );
    expect(find.text('Home'), findsWidgets);
  });
}

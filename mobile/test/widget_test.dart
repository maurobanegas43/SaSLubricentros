import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LubricentrosApp());
    
    // Verify login screen is shown
    expect(find.text('Lubricentros'), findsOneWidget);
  });
}

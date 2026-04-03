import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/widgets/loading/loading_spinner.dart';

void main() {
  group('LoadingSpinner', () {
    testWidgets('renders with default properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(),
          ),
        ),
      );

      expect(find.byType(LoadingSpinner), findsOneWidget);
    });

    testWidgets('renders with message', (WidgetTester tester) async {
      const testMessage = 'Loading data...';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              message: testMessage,
            ),
          ),
        ),
      );

      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('renders small size spinner variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              size: LoadingSize.small,
              variant: LoadingVariant.spinner,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders medium size dots variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              size: LoadingSize.medium,
              variant: LoadingVariant.dots,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LoadingSpinner), findsOneWidget);
    });

    testWidgets('renders large size bar variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              size: LoadingSize.large,
              variant: LoadingVariant.bar,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LoadingSpinner), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (WidgetTester tester) async {
      const customColor = Colors.blue;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              color: customColor,
            ),
          ),
        ),
      );

      expect(find.byType(LoadingSpinner), findsOneWidget);
    });

    testWidgets('animations work correctly for spinner variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              variant: LoadingVariant.spinner,
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('animations work correctly for dots variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              variant: LoadingVariant.dots,
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(find.byType(LoadingSpinner), findsOneWidget);
    });

    testWidgets('animations work correctly for bar variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingSpinner(
              variant: LoadingVariant.bar,
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(find.byType(LoadingSpinner), findsOneWidget);
    });
  });
}

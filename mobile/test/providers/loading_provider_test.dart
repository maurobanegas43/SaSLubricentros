import 'package:flutter_test/flutter_test.dart';
import 'package:lubricentros_app/providers/loading_provider.dart';

void main() {
  group('LoadingProvider', () {
    late LoadingProvider provider;

    setUp(() {
      provider = LoadingProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state is not loading', () {
      expect(provider.isLoading, false);
      expect(provider.message, null);
      expect(provider.activeOperations, 0);
    });

    test('showLoading sets loading state', () {
      provider.showLoading();

      expect(provider.isLoading, true);
      expect(provider.activeOperations, 1);
    });

    test('showLoading with message stores the message', () {
      const testMessage = 'Loading data...';
      provider.showLoading(testMessage);

      expect(provider.isLoading, true);
      expect(provider.message, testMessage);
    });

    test('hideLoading removes loading state', () {
      provider.showLoading();
      expect(provider.isLoading, true);

      provider.hideLoading();
      expect(provider.isLoading, false);
      expect(provider.activeOperations, 0);
    });

    test('hideLoading with ID removes specific operation', () {
      final id1 = provider.showLoading('Operation 1');
      final id2 = provider.showLoading('Operation 2');

      expect(provider.activeOperations, 2);

      provider.hideLoading(id1);
      expect(provider.activeOperations, 1);
      expect(provider.message, 'Operation 2');

      provider.hideLoading(id2);
      expect(provider.isLoading, false);
    });

    test('queue supports multiple loading operations', () {
      provider.showLoading('Operation 1');
      provider.showLoading('Operation 2');
      provider.showLoading('Operation 3');

      expect(provider.activeOperations, 3);
      expect(provider.isLoading, true);
      expect(provider.message, 'Operation 3'); // Most recent
    });

    test('hideLoading without ID removes most recent operation', () {
      provider.showLoading('Operation 1');
      provider.showLoading('Operation 2');
      provider.showLoading('Operation 3');

      provider.hideLoading(); // Removes Operation 3
      expect(provider.activeOperations, 2);
      expect(provider.message, 'Operation 2');

      provider.hideLoading(); // Removes Operation 2
      expect(provider.activeOperations, 1);
      expect(provider.message, 'Operation 1');
    });

    test('clearAll removes all loading operations', () {
      provider.showLoading('Operation 1');
      provider.showLoading('Operation 2');
      provider.showLoading('Operation 3');

      expect(provider.activeOperations, 3);

      provider.clearAll();
      expect(provider.isLoading, false);
      expect(provider.activeOperations, 0);
      expect(provider.message, null);
    });

    test('withLoading manages loading state automatically', () async {
      expect(provider.isLoading, false);

      final future = provider.withLoading(() async {
        expect(provider.isLoading, true);
        await Future.delayed(const Duration(milliseconds: 10));
        return 'result';
      });

      expect(provider.isLoading, true);

      final result = await future;
      expect(result, 'result');
      expect(provider.isLoading, false);
    });

    test('withLoading with message sets the message', () async {
      const testMessage = 'Processing...';

      final future = provider.withLoading(
        () async {
          expect(provider.message, testMessage);
          await Future.delayed(const Duration(milliseconds: 10));
          return 'done';
        },
        message: testMessage,
      );

      expect(provider.message, testMessage);
      await future;
      expect(provider.message, null);
    });

    test('withLoading hides loading even if operation throws', () async {
      expect(provider.isLoading, false);

      try {
        await provider.withLoading(() async {
          expect(provider.isLoading, true);
          throw Exception('Test error');
        });
      } catch (e) {
        // Expected error
      }

      expect(provider.isLoading, false);
    });

    test('notifies listeners when loading state changes', () {
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
      });

      provider.showLoading();
      expect(notificationCount, 1);

      provider.hideLoading();
      expect(notificationCount, 2);

      provider.showLoading('Message');
      expect(notificationCount, 3);

      provider.clearAll();
      expect(notificationCount, 4);
    });

    test('operations list is unmodifiable', () {
      provider.showLoading('Operation 1');
      final operations = provider.operations;

      expect(() => operations.add(LoadingOperation(id: 'test')),
          throwsUnsupportedError);
    });

    test('hideLoading does nothing when queue is empty', () {
      expect(provider.isLoading, false);
      provider.hideLoading();
      expect(provider.isLoading, false);
    });

    test('clearAll does nothing when queue is empty', () {
      expect(provider.isLoading, false);
      provider.clearAll();
      expect(provider.isLoading, false);
    });

    test('each showLoading returns unique ID', () {
      final id1 = provider.showLoading();
      final id2 = provider.showLoading();
      final id3 = provider.showLoading();

      expect(id1, isNot(equals(id2)));
      expect(id2, isNot(equals(id3)));
      expect(id1, isNot(equals(id3)));
    });
  });
}

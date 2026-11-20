import 'package:flutter/foundation.dart';

/// Represents a single loading operation in the queue
class LoadingOperation {
  final String id;
  final String? message;
  final DateTime timestamp;

  LoadingOperation({
    required this.id,
    this.message,
  }) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingOperation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Global loading state provider with queue support for multiple simultaneous operations
class LoadingProvider extends ChangeNotifier {
  final List<LoadingOperation> _loadingQueue = [];

  /// Returns true if any loading operation is active
  bool get isLoading => _loadingQueue.isNotEmpty;

  /// Returns the message of the most recent loading operation, if any
  String? get message =>
      _loadingQueue.isNotEmpty ? _loadingQueue.last.message : null;

  /// Returns the number of active loading operations
  int get activeOperations => _loadingQueue.length;

  /// Returns all active loading operations
  List<LoadingOperation> get operations => List.unmodifiable(_loadingQueue);

  /// Shows a loading indicator with an optional message
  /// Returns a unique ID that should be used to hide this specific loading operation
  String showLoading([String? message]) {
    final id = _generateId();
    final operation = LoadingOperation(id: id, message: message);
    _loadingQueue.add(operation);
    notifyListeners();
    return id;
  }

  /// Hides a specific loading operation by ID
  /// If no ID is provided, removes the most recent loading operation
  void hideLoading([String? id]) {
    if (_loadingQueue.isEmpty) return;

    if (id != null) {
      _loadingQueue.removeWhere((op) => op.id == id);
    } else {
      _loadingQueue.removeLast();
    }

    notifyListeners();
  }

  /// Clears all loading operations
  void clearAll() {
    if (_loadingQueue.isEmpty) return;
    _loadingQueue.clear();
    notifyListeners();
  }

  /// Wraps an async operation with automatic loading state management
  /// Shows loading before the operation and hides it after completion
  Future<T> withLoading<T>(
    Future<T> Function() operation, {
    String? message,
  }) async {
    final id = showLoading(message);
    try {
      return await operation();
    } finally {
      hideLoading(id);
    }
  }

  /// Generates a unique ID for loading operations
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_loadingQueue.length}';
  }

  @override
  void dispose() {
    _loadingQueue.clear();
    super.dispose();
  }
}

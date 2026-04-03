/// Unified loading/data/error state pattern.
/// Replaces separate isLoading/isError/data fields with a single source of truth.
sealed class AsyncValue<T> {
  const AsyncValue();
  bool get isLoading => this is AsyncLoading<T>;
  bool get hasData => this is AsyncData<T>;
  bool get hasError => this is AsyncError<T>;
  T? get dataOrNull => this is AsyncData<T> ? (this as AsyncData<T>).data : null;
  String? get errorOrNull => this is AsyncError<T> ? (this as AsyncError<T>).message : null;
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(String message) error,
  }) {
    final self = this;
    if (self is AsyncLoading<T>) return loading();
    if (self is AsyncData<T>) return data(self.data);
    if (self is AsyncError<T>) return error(self.message);
    throw StateError('Unknown AsyncValue state');
  }
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  final T data;
  const AsyncData(this.data);
}

class AsyncError<T> extends AsyncValue<T> {
  final String message;
  final Object? originalError;
  const AsyncError(this.message, {this.originalError});
}

enum AppStatus {
  idle,
  loading,
  success,
  error,
}

class AppState<T, E extends Object> {
  final T? data;
  final E? error;
  final AppStatus status;
  final String? message;

  const AppState._({
    this.data,
    this.error,
    required this.status,
    this.message,
  });

  factory AppState.idle() => AppState._(status: AppStatus.idle);
  factory AppState.loading() => AppState._(status: AppStatus.loading);
  factory AppState.success(T data, {String? message}) => AppState._(
        status: AppStatus.success,
        data: data,
        message: message,
      );
  factory AppState.error(E error, {String? message}) => AppState._(
        status: AppStatus.error,
        error: error,
        message: message ?? error.toString(),
      );
  bool get isIdle => status == AppStatus.idle;
  bool get isLoading => status == AppStatus.loading;
  bool get isSuccess => status == AppStatus.success;
  bool get isError => status == AppStatus.error;

  AppState<T, E> copyWith({
    T? data,
    E? error,
    AppStatus? status,
    String? message,
  }) {
    return AppState._(
        data: data ?? this.data,
        error: error ?? this.error,
        status: status ?? this.status,
        message: message ?? this.message);
  }

  @override
  String toString() {
    return 'AppState{data: $data, error: $error, status: $status, message: $message}';
  }

  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(E error, String? message) error,
  }) {
    switch (status) {
      case AppStatus.idle:
        return idle();
      case AppStatus.loading:
        return loading();
      case AppStatus.success:
        return success(data as T);
      case AppStatus.error:
      return error(error as E, message);
    }
  }

  /// Use pattern matching to handle different states, with default case
  R maybeWhen<R>({
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(E error, String? message)? error,
    required R Function() orElse,
  }) {
    switch (status) {
      case AppStatus.idle:
        return idle != null ? idle() : orElse();
      case AppStatus.loading:
        return loading != null ? loading() : orElse();
      case AppStatus.success:
        return success != null ? success(data as T) : orElse();
      case AppStatus.error:
        return error != null ? error(error as E, message) : orElse();
    }
  }
}

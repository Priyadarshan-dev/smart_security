enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? role;

  AuthState({required this.status, this.error, this.role});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({AuthStatus? status, String? error, String? role}) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      role: role ?? this.role,
    );
  }
}

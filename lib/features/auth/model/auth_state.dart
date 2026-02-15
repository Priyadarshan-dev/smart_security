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

  Map<String, dynamic> toJson() {
    return {'status': status.name, 'error': error, 'role': role};
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      status: AuthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AuthStatus.initial,
      ),
      error: json['error'],
      role: json['role'],
    );
  }
}

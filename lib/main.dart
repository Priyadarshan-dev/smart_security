import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/auth/controller/auth_state.dart';
import 'features/auth/view/login_screen.dart';
import 'features/tenant_admin/view/tenant_admin_dashboard.dart';
import 'features/security/view/security_dashboard.dart';

void main() {
  runApp(const ProviderScope(child: SmartSecurityApp()));
}

class SmartSecurityApp extends ConsumerStatefulWidget {
  const SmartSecurityApp({super.key});

  @override
  ConsumerState<SmartSecurityApp> createState() => _SmartSecurityAppState();
}

class _SmartSecurityAppState extends ConsumerState<SmartSecurityApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Smart Security',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: _getHome(authState),
    );
  }

  Widget _getHome(AuthState state) {
    if (state.status == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == AuthStatus.authenticated) {
      if (state.role == "TENANT_ADMIN") {
        return const TenantAdminDashboard();
      } else {
        return const SecurityDashboard();
      }
    }
    return const LoginScreen();
  }
}

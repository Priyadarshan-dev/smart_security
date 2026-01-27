import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/auth/controller/auth_state.dart';
import 'features/auth/view/login_screen.dart';
import 'features/tenant_admin/view/tenant_admin_dashboard.dart';
import 'features/security/view/security_dashboard.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initializeNotifications();
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
    Future.microtask(() async {
      await ref.read(authProvider.notifier).checkAuth();
      // Request notification permissions after the app has started and initial auth check is done
      await NotificationService().requestFullPermissions();
    });
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
      final role = state.role?.toUpperCase().trim();
      if (role == "TENANT_ADMIN") {
        return const TenantAdminDashboard();
      } else {
        // Default to SecurityDashboard for security guards or other roles
        return const SecurityDashboard();
      }
    }
    return const LoginScreen();
  }
}

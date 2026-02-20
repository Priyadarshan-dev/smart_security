import 'package:ceedeeyes/core/storage/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/model/auth_state.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/tenant_admin/screens/tenant_admin_dashboard.dart';
import 'features/security/screens/security_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final storage = StorageService();
  final token = await storage.getToken();

  if (token != null) {
  } else {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Register background handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
      await NotificationService().initializeNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != AuthStatus.authenticated &&
          next.status == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
      }
    });

    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Smart Security',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      navigatorKey: navigatorKey,
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

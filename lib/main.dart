import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/admin_signup_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/classroom/screens/classroom_management_screen.dart';
import 'features/admin/screens/admin_management_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/services/localization_service.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize LocalizationService
  await LocalizationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = LocalizationService.instance.currentLocale;

  @override
  void initState() {
    super.initState();

    // Listen to locale changes
    LocalizationService.instance.localeStream.listen((locale) {
      setState(() {
        _locale = locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attenglish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Localization delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Supported locales
      supportedLocales: LocalizationService.supportedLocales,

      // Current locale
      locale: _locale,

      // Builder to set text direction based on locale
      builder: (context, child) {
        return Directionality(
          textDirection: LocalizationService.instance.textDirection,
          child: child!,
        );
      },

      // Use home with StreamBuilder for auth state
      home: const AuthStateHandler(),

      // Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/admin-signup': (context) => const AdminSignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/classrooms': (context) => const ClassroomManagementScreen(),
        '/admin': (context) => const AdminManagementScreen(),
      },
    );
  }
}

/// Handles authentication state and routes to appropriate screen
class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, go to home
          return const HomeScreen();
        } else {
          // User is not logged in, go to login
          return const LoginScreen();
        }
      },
    );
  }
}

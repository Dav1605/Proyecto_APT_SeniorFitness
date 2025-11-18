// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:senior_fitness_app/screens/home_screen.dart';
import 'package:senior_fitness_app/screens/login_screen.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Inicializa Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(SeniorFitnessApp(analytics: analytics));
}

class SeniorFitnessApp extends StatelessWidget {
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  SeniorFitnessApp({super.key, required this.analytics})
      : observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppPalette.primary,
        scaffoldBackgroundColor: AppPalette.background,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppPalette.secondary,
        ),
      ),
      // 🔹 Observador de navegación (para registrar screen_view en Analytics)
      navigatorObservers: [observer],
      home: const AuthGate(),
    );
  }
}

/// 🔐 Control de autenticación global
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Mientras Firebase inicializa
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Usuario autenticado → pasar userId a HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return HomeScreen(userId: user.uid);
        }

        // 🔒 Usuario no autenticado → mostrar login
        return const LoginScreen();
      },
    );
  }
}

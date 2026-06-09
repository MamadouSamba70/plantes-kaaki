import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/admin/superadmin_dashboard.dart';
import '../screens/agronomist/agronomist_dashboard.dart';
import '../screens/researcher/researcher_dashboard.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Public ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // ── SuperAdmin ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) => const SuperAdminDashboard(),
    ),

    // ── Agronomist ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/agronomy',
      builder: (context, state) => const AgronomistDashboard(),
    ),

    // ── Researcher ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/research',
      builder: (context, state) => const ResearcherDashboard(),
    ),

    // ── User (Farmer) ────────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

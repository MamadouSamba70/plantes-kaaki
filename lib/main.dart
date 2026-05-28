import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/scan_provider.dart';
import 'routes/router.dart';

import 'core/services/api_service.dart';

void main() async {
  // Ensure widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize HTTP API Service (loads local token)
  await ApiService.init();

  // Safe Firebase Initialization
  // If configuration files (google-services.json / GoogleService-Info.plist) are missing,
  // it throws an exception, which we catch. The services will automatically detect this and switch to Mock Mode.
  try {
    await Firebase.initializeApp();
    debugPrint("KaakiScan: Firebase initialized successfully.");
  } catch (e) {
    debugPrint("KaakiScan: Firebase initialization failed. Falling back to local offline mode. Error: $e");
  }

  runApp(const KaakiScanApp());
}

class KaakiScanApp extends StatelessWidget {
  const KaakiScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: MaterialApp.router(
        title: 'KaakiScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}

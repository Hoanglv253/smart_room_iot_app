import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_keys.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartRoomApp());
}

class SmartRoomApp extends StatelessWidget {
  const SmartRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apart-Hub',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

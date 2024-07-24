import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screens/login.dart';

import 'firebase_options.dart';
import 'screens/admin.dart';
import 'screens/homepage.dart';
import 'screens/nav.dart';
import 'screens/profile.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.redAccent, brightness: Brightness.dark),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/nav': (context) => const NavPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}

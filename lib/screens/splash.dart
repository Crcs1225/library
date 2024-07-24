import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // Fetch current user
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, fetch admin status
        final adminDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final adminSnapshot = await adminDoc.get();

        if (mounted) {
          if (adminSnapshot.exists &&
              adminSnapshot.data()?['is_admin'] == true) {
            // Admin is logged in, navigate to the admin page
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            // Regular user is logged in, navigate to the homepage
            Navigator.pushReplacementNamed(context, '/nav');
          }
        }
      } else {
        // User is not logged in, navigate to the login page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // Handle any errors during the authentication or Firestore operations
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/bsu-logo.svg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ), // Placeholder for logo or other content
    );
  }
}

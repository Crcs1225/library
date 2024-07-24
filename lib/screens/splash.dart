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

        // Schedule navigation after the current frame is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (adminSnapshot.exists &&
                adminSnapshot.data()?['is_admin'] == true) {
              Navigator.pushReplacementNamed(context, '/admin');
            } else {
              Navigator.pushReplacementNamed(context, '/nav');
            }
          }
        });
      } else {
        // User is not logged in, navigate to the login page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    } catch (e) {
      // Handle any errors during the authentication or Firestore operations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                'assets/bsu-logo.svg',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ), // Placeholder for logo or other content
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Check user status after the frame is built
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // User is logged in, check if user is admin
          final adminDoc =
              FirebaseFirestore.instance.collection('users').doc(user.uid);
          final adminSnapshot = await adminDoc.get();

          if (adminSnapshot.exists &&
              adminSnapshot.data()?['is_admin'] == true) {
            // Admin is logged in, navigate to the admin page
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            // Regular user is logged in, navigate to the homepage
            Navigator.pushReplacementNamed(context, '/nav');
          }
        } else {
          // User is not logged in, navigate to the login page
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        // Handle any errors during the authentication or Firestore operations
        print('Error during navigation check: $e');
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

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
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ), // Placeholder for logo or other content
    );
  }
}

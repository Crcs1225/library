import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check user status after the frame is built
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, check if user is admin
        final adminDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final adminSnapshot = await adminDoc.get();

        if (adminSnapshot.exists && adminSnapshot.data()?['is_admin'] == true) {
          // Admin is logged in, navigate to the admin page
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          // Regular user is logged in, navigate to the homepage
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // User is not logged in, navigate to the login page
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return const Scaffold(
      body: Center(
          child: Column(
        children: [CircularProgressIndicator()],
      )), //logo here
    );
  }
}

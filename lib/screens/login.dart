import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  void _login() async {
    try {
      // Sign in with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      // Fetch the user from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Check if the document exists and perform necessary actions
      if (userDoc.exists) {
        // For example, you can check user data and navigate based on roles
        var userData = userDoc.data() as Map<String, dynamic>;

        if (userData['is_admin'] == true) {
          // Navigate to admin page
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          // Navigate to user home page
          Navigator.pushReplacementNamed(context, '/nav');
        }
      } else {
        // Handle the case where the user document does not exist
        // For example, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found in Firestore')),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Tagline
                Column(
                  children: [
                    // Replace with your logo widget or image
                    SvgPicture.asset(
                      'assets/bsu-log.svg',
                      width: 200,
                      height: 200,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Library Seat Reservation',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
                // Username Text Field
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username or Email',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.2),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password Text Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.2),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 18), // Optional: Set text size
                    foregroundColor: Colors.white, // Text color
                    backgroundColor: Colors.redAccent, // Accent red background
                    minimumSize: const Size(double.infinity,
                        50.0), // Full width, adjust height as needed
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10.0), // Optional: Rounded corners
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

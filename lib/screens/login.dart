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
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    final email = _usernameController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password must not be empty');
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Sign in with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
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
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/admin');
          }
        } else {
          // Navigate to user home page
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/nav');
          }
        }
      } else {
        // Handle the case where the user document does not exist
        // For example, show an error message
        _showError('User data not found in Firestore');
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      _showError(e.message ?? 'Login failed');
    } catch (e) {
      // Handle other errors
      _showError('An unexpected error occurred');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.grey.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Tagline
                    Column(
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
                                offset: const Offset(
                                    0, 3), // changes position of shadow
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
                        const SizedBox(height: 16),
                        const Text(
                          'Library Seat Reservation',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                    // Username Text Field
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                            fontSize: 18), // Optional: Set text size
                        foregroundColor: Colors.white, // Text color
                        backgroundColor:
                            Colors.redAccent, // Accent red background
                        minimumSize: const Size(double.infinity,
                            50.0), // Full width, adjust height as needed
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Optional: Rounded corners
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

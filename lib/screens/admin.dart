import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMonitorPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('seats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final seats = snapshot.data?.docs ?? [];
        final availableSeats = seats.where((seat) => !seat['reserved']).length;
        final reservedSeats = seats.where((seat) => seat['reserved']).length;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Available Seats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        availableSeats.toString(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Reserved Seats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reservedSeats.toString(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addUser(String email, String password, String studentId) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'studentId': studentId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $e')),
      );
    }
  }

  void _reserveSeatForUser(String seatNumber, String studentId) async {
  try {
    // Check if the user exists
    QuerySnapshot userSnapshot = await _firestore
        .collection('users')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    // Get the user ID
    String uid = userSnapshot.docs.first.id;

    // Check if the seat exists and is not reserved
    QuerySnapshot seatSnapshot = await _firestore
        .collection('seats')
        .where('seatNumber', isEqualTo: int.parse(seatNumber))
        .limit(1)
        .get();

    if (seatSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat not found')),
      );
      return;
    }

    DocumentSnapshot seatDoc = seatSnapshot.docs.first;
    bool isReserved = seatDoc['reserved'];

    if (isReserved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat is already reserved')),
      );
      return;
    }

    // Update the seat document
    await _firestore.collection('seats').doc(seatDoc.id).update({
      'reserved': true,
      'reservedBy': uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seat reserved successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to reserve seat: $e')),
    );
  }
}


  void _makeSeatAvailable(String seatNumber) async {
  try {
    // Query for the seat document based on the seatNumber field
    QuerySnapshot seatSnapshot = await _firestore
        .collection('seats')
        .where('seatNumber', isEqualTo: int.parse(seatNumber))
        .limit(1)
        .get();

    if (seatSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat not found')),
      );
      return;
    }

    DocumentSnapshot seatDoc = seatSnapshot.docs.first;

    // Update the seat document
    await _firestore.collection('seats').doc(seatDoc.id).update({
      'reserved': false,
      'reservedBy': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seat made available successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to make seat available: $e')),
    );
  }
}
void _logout() async {
  try {
    await FirebaseAuth.instance.signOut();
    
    // Navigate to the login screen
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust the route name if needed
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to logout: $e')),
    );
  }
}



  void _showAddUserDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addUser(
                  emailController.text,
                  passwordController.text,
                  studentIdController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagePage() {
    final TextEditingController seatController = TextEditingController();
    final TextEditingController studentIdController = TextEditingController();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _showAddUserDialog,
                      child: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reserve Seat for User',
                        style: TextStyle(fontSize: 20)),
                    TextField(
                      controller: seatController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        filled: true, // Enables fill color
                        fillColor: Colors.grey
                            .withOpacity(0.2), // Set fill color (optional)
                        contentPadding: const EdgeInsets.all(
                            16.0), // Adjust content padding
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.transparent), // Remove underline
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: studentIdController,
                      decoration: InputDecoration(
                        labelText: 'Student ID',
                        filled: true, // Enables fill color
                        fillColor: Colors.grey
                            .withOpacity(0.2), // Set fill color (optional)
                        contentPadding: const EdgeInsets.all(
                            16.0), // Adjust content padding
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.transparent), // Remove underline
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _reserveSeatForUser(
                          seatController.text, studentIdController.text),
                      child: const Text('Reserve Seat'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Make Seat Available',
                        style: TextStyle(fontSize: 20)),
                    TextField(
                      controller: seatController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        filled: true, // Enables fill color
                        fillColor: Colors.grey
                            .withOpacity(0.2), // Set fill color (optional)
                        contentPadding: const EdgeInsets.all(
                            16.0), // Adjust content padding
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.transparent), // Remove underline
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _makeSeatAvailable(seatController.text),
                      child: const Text('Make Available'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildMonitorPage(),
      _buildManagePage(),
    ];

    return Scaffold(
      appBar: AppBar(
  title: const Text('Admin Dashboard'),
  backgroundColor: Colors.black.withOpacity(0.8),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _logout,
    ),
  ],
),

      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Manage',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

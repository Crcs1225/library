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

  // Controllers for dialogs and input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _seatController = TextEditingController();
  final TextEditingController _studentIdForReservationController =
      TextEditingController();
  final TextEditingController _deleteUserEmailController =
      TextEditingController();
  final TextEditingController _seatDetailsController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _courseController.dispose();
    _seatController.dispose();
    _studentIdForReservationController.dispose();
    _deleteUserEmailController.dispose();
    _seatDetailsController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Map<String, dynamic> _seatDetails = {};

  void _fetchSeatDetails() async {
    // Parse the seat number input as an integer
    final seatNumberStr = _seatDetailsController.text;
    final int? seatNumber = int.tryParse(seatNumberStr);

    if (seatNumber != null) {
      // Fetch seat details from Firestore
      var seatQuery = await FirebaseFirestore.instance
          .collection('seats')
          .where('seatNumber',
              isEqualTo: seatNumber) // Assuming seatNumber is a field
          .limit(1) // Limit to one document
          .get();

      if (seatQuery.docs.isNotEmpty) {
        var seatData = seatQuery.docs.first.data();
        bool isReserved = seatData['reserved'] ?? false;
        String status;

        if (isReserved) {
          var reservedByUid = seatData['reservedBy'];
          if (reservedByUid != null) {
            // Fetch student ID from users collection
            var userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(reservedByUid)
                .get();

            if (userDoc.exists) {
              var userData = userDoc.data();
              var studentId = userData?['studentId'] ?? 'Unknown';
              status = studentId;
            } else {
              status = 'User not found';
            }
          } else {
            status = 'Reserved but user info missing';
          }
        } else {
          status = 'Available';
        }

        setState(() {
          _seatDetails = {
            'seatNumber': seatNumber,
            'status': status,
          };
        });
      } else {
        setState(() {
          _seatDetails = {'status': 'Not Found'};
        });
      }
    } else {
      setState(() {
        _seatDetails = {'status': 'Invalid seat number'};
      });
    }
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
        final availableSeats =
            seats.where((seat) => !seat['reserved']).toList();
        final reservedSeats = seats.where((seat) => seat['reserved']).length;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
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
                          availableSeats.length.toString(),
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
                const SizedBox(height: 16),
                const Text(
                  'Available Seats List',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: availableSeats.length,
                  itemBuilder: (context, index) {
                    final seat = availableSeats[index];
                    final seatNumber = seat['seatNumber'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading:
                            const Icon(Icons.event_seat, color: Colors.white),
                        title: Text('Seat $seatNumber'),
                        trailing:
                            const Icon(Icons.check_circle, color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addUser() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final studentId = _studentIdController.text.trim();
      final course = _courseController.text.trim();

      if (email.isEmpty ||
          password.isEmpty ||
          studentId.isEmpty ||
          course.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields must be filled')),
        );
        return;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'studentId': studentId,
        'course': course,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully')),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $e')),
        );
      }
    }
  }

  void _reserveSeatForUser() async {
    try {
      final seatNumber = _seatController.text.trim();
      final studentId = _studentIdForReservationController.text.trim();

      if (seatNumber.isEmpty || studentId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Seat Number and Student ID are required')),
        );
        return;
      }

      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      String uid = userSnapshot.docs.first.id;
      QuerySnapshot seatSnapshot = await _firestore
          .collection('seats')
          .where('seatNumber', isEqualTo: int.parse(seatNumber))
          .limit(1)
          .get();

      if (seatSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat not found')),
          );
        }
        return;
      }

      DocumentSnapshot seatDoc = seatSnapshot.docs.first;
      bool isReserved = seatDoc['reserved'];

      if (isReserved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat is already reserved')),
          );
        }
        return;
      }

      await _firestore.collection('seats').doc(seatDoc.id).update({
        'reserved': true,
        'reservedBy': uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat reserved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reserve seat: $e')),
        );
      }
    }
  }

  void _makeSeatAvailable() async {
    try {
      final seatNumber = _seatController.text.trim();

      if (seatNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat Number is required')),
        );
        return;
      }

      QuerySnapshot seatSnapshot = await _firestore
          .collection('seats')
          .where('seatNumber', isEqualTo: int.parse(seatNumber))
          .limit(1)
          .get();

      if (seatSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat not found')),
          );
        }
        return;
      }

      DocumentSnapshot seatDoc = seatSnapshot.docs.first;
      bool isReserved = seatDoc['reserved'];

      if (!isReserved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seat is already available')),
          );
        }
        return;
      }

      await _firestore.collection('seats').doc(seatDoc.id).update({
        'reserved': false,
        'reservedBy': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat made available successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make seat available: $e')),
        );
      }
    }
  }

  void _logout() async {
    // Show a confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // No
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Yes
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // Proceed with logout if user confirmed
    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        } // Adjust the route name if needed
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to logout: $e')),
          );
        }
      }
    }
  }

  void _deleteUser() async {
    try {
      final email = _deleteUserEmailController.text.trim();

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is required')),
        );
        return;
      }

      // Fetch the user document from Firestore
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      DocumentSnapshot userDoc = userSnapshot.docs.first;
      String uid = userDoc.id; // Get the user ID

      // Delete user from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Authentication
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await currentUser.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addUser,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: TextField(
            controller: _deleteUserEmailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteUser();
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showStudentListDialog() async {
    try {
      // Fetch the list of students from Firestore
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      List<DocumentSnapshot> users = userSnapshot.docs;

      // Filter documents that have a studentId field
      List<DocumentSnapshot> filteredUsers = users.where((user) {
        final data = user.data() as Map<String, dynamic>;
        return data.containsKey('studentId');
      }).toList();

      // Build the list of students with studentId and course
      List<Widget> studentWidgets = filteredUsers.map((user) {
        final data = user.data() as Map<String, dynamic>;
        final studentId = data['studentId'] ?? 'No Student ID';
        final course = data['course'] ?? 'No Course';

        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(studentId),
              Text(course),
            ],
          ),
        );
      }).toList();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('List of Students'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: studentWidgets,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to list students: $e')),
        );
      }
    }
  }

  Widget _buildManagePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for Add User, Delete User, and List Students buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: _showAddUserDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_add,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a new user to the system.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: _showDeleteUserDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Delete User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Remove a user from the system.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: InkWell(
                      onTap: _showStudentListDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.list,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'List Students',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View a list of all students.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Card for reserving seats
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
                      controller: _seatController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.2),
                        contentPadding: const EdgeInsets.all(16.0),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _studentIdForReservationController,
                      decoration: InputDecoration(
                        labelText: 'Student ID',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.2),
                        contentPadding: const EdgeInsets.all(16.0),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _reserveSeatForUser,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Center(
                          child: Text(
                            'Reserve Seat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card for making seats available
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
                      controller: _seatController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.2),
                        contentPadding: const EdgeInsets.all(16.0),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _makeSeatAvailable,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Center(
                          child: Text(
                            'Make Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card for viewing seat details
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('View Seat Details',
                        style: TextStyle(fontSize: 20)),
                    TextField(
                      controller: _seatDetailsController,
                      decoration: InputDecoration(
                        labelText: 'Seat Number',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.2),
                        contentPadding: const EdgeInsets.all(16.0),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _fetchSeatDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Center(
                          child: Text(
                            'Fetch Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _seatDetails.isNotEmpty
                        ? Text(
                            'Seat Number: ${_seatDetails['seatNumber']}\n'
                            'Status: ${_seatDetails['status']}'
                            '${_seatDetails.containsKey('reservedBy') ? "\nReserved By: ${_seatDetails['reservedBy']}" : ""}',
                            style: const TextStyle(fontSize: 16),
                          )
                        : const Text('No details available.',
                            style: TextStyle(fontSize: 16)),
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
        automaticallyImplyLeading: false,
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

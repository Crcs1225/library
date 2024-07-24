import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Stream<QuerySnapshot> _seatsStream =
      FirebaseFirestore.instance.collection('seats').snapshots();

  Future<void> _reserveSeats(List<String> seatNumbers) async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    // Track errors for each seat number
    final errorMessages = <String>[];

    try {
      for (var seatNumberString in seatNumbers) {
        final seatNumber = int.tryParse(seatNumberString); // Convert to int

        if (seatNumber == null) {
          // Skip invalid seat numbers and add an error message
          errorMessages.add('Invalid seat number: $seatNumberString');
          continue;
        }

        final seatQuery = await _firestore
            .collection('seats')
            .where('seatNumber', isEqualTo: seatNumber)
            .limit(1)
            .get();

        if (seatQuery.docs.isNotEmpty) {
          final seatDoc = seatQuery.docs.first;
          final seatId = seatDoc.id;
          final isReserved = seatDoc['reserved'];
          final reservedBy = seatDoc['reservedBy'];

          if (!isReserved || (reservedBy == user.uid)) {
            // Allow reservation if the seat is not reserved or reserved by the same user
            await _firestore.collection('seats').doc(seatId).update({
              'reserved': true,
              'reservedBy': user.uid,
            });
          } else {
            // Add an error message if the seat is reserved by someone else
            errorMessages.add(
                'Seat number $seatNumber is already reserved by another user.');
          }
        } else {
          // Add an error message if the seat number is not found
          errorMessages.add('Seat number $seatNumber not found.');
        }
      }

      // Show success message if no errors occurred
      if (errorMessages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seats reserved successfully')),
          );
        }
      } else {
        // Show all error messages
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessages.join('\n'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reserve seats: $e')),
        );
      }
    }
  }

  Future<void> _showReservationDialog() async {
    final seatNumbersController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reserve Seats'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter seat numbers separated by commas:'),
              TextField(
                controller: seatNumbersController,
                decoration: const InputDecoration(hintText: 'e.g. 1, 2, 3'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, <String>[]), // Return empty list
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final seatNumbers = seatNumbersController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty) // Ensure non-empty strings
                    .toList();
                Navigator.pop(context, seatNumbers);
              },
              child: const Text('Reserve'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Convert result to List<String> if necessary
      final seatNumbers = result.map((e) => e.toString()).toList();
      _reserveSeats(seatNumbers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Seat Reservation'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _seatsStream,
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
            seats.where((seat) => seat['reserved']).toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_seat, size: 40),
                          const SizedBox(width: 16),
                          Text(
                            '${availableSeats.length} seats available',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSeatsSection('Seats', seats),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReservationDialog,
        backgroundColor: Colors.white,
        tooltip: 'Reserve Seats',
        child: const Icon(
          Icons.add,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildSeatsSection(String title, List<QueryDocumentSnapshot> seats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 seats per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: seats.length,
          itemBuilder: (context, index) {
            final seatDoc = seats[index];
            final bool isReserved = seatDoc['reserved'];
            final String seatNumber = seatDoc['seatNumber'].toString();

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: isReserved ? Colors.redAccent : Colors.grey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_seat, size: 40, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'Seat $seatNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

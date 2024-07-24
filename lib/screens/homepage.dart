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

  void _toggleReservation(String seatId, bool isReserved) async {
    try {
      await _firestore.collection('seats').doc(seatId).update({
        'reserved': !isReserved,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update seat: $e')),
      );
    }
  }

  Future<void> _reserveGroup() async {
    // Show a bottom sheet to select the number of seats to reserve
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int groupSize = 2; // Default group size

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reserve Seats for Group',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: groupSize.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: groupSize.toString(),
                    onChanged: (value) {
                      setState(() {
                        groupSize = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _findAndReserveGroup(groupSize);
                      Navigator.pop(context);
                    },
                    child: const Text('Reserve'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _findAndReserveGroup(int groupSize) async {
    try {
      final seatsSnapshot = await _firestore
          .collection('seats')
          .where('reserved', isEqualTo: false)
          .orderBy('seatNumber')
          .get();
      final availableSeats = seatsSnapshot.docs;

      List<String> seatsToReserve = [];
      int consecutiveCount = 0;

      for (var seat in availableSeats) {
        seatsToReserve.add(seat.id);
        consecutiveCount++;

        if (consecutiveCount == groupSize) {
          break;
        }
      }

      if (seatsToReserve.length == groupSize) {
        final user = _auth.currentUser;

        if (user != null) {
          // Update Firestore with reserved seats
          for (var seatId in seatsToReserve) {
            await _firestore
                .collection('seats')
                .doc(seatId)
                .update({'reserved': true});
          }

          // Update the user's profile with the reserved seats
          final userDoc = _firestore.collection('users').doc(user.uid);
          final userSnapshot = await userDoc.get();
          final reservedSeats =
              (userSnapshot.data()?['reservedSeats'] as List?) ?? [];

          await userDoc.update({
            'reservedSeats': [...reservedSeats, ...seatsToReserve],
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group reserved successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Not enough consecutive seats available')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reserve group: $e')),
      );
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
            final reservedSeats =
                seats.where((seat) => seat['reserved']).toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildSeatsSection('Available Seats', availableSeats),
                  _buildSeatsSection('Reserved Seats', reservedSeats),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reserveGroup,
        child: const Icon(Icons.group_add),
        backgroundColor: Colors.redAccent,
        tooltip: 'Reserve Group',
      ),
    );
  }

  Widget _buildSeatsSection(String title, List<QueryDocumentSnapshot> seats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 5 seats per row
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: seats.length,
            itemBuilder: (context, index) {
              final seatDoc = seats[index];
              final bool isReserved = seatDoc['reserved'];
              final String seatId = seatDoc.id;

              return GestureDetector(
                onTap: () {
                  _toggleReservation(seatId, isReserved);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isReserved ? Colors.redAccent : Colors.grey,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.black.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      seatDoc['seatNumber'].toString(), // Seat number
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

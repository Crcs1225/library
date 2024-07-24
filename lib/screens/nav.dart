import 'package:flutter/material.dart';
import 'package:myapp/screens/homepage.dart';
import 'package:myapp/screens/profile.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? const HomePage()
          : const ProfilePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.redAccent, // Active color
        unselectedItemColor: Colors.grey, // Inactive color
        backgroundColor: Colors.black.withOpacity(0.8), // Background color
        type: BottomNavigationBarType.fixed, // Ensures items do not scroll
      ),
    );
  }
}


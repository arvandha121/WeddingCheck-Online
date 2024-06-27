import 'package:flutter/material.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role;

  const MyBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.role,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: "Home",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner_outlined),
        label: "Scan",
      ),
      if (role == 'admin')
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2),
          label: "Management",
        ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: "Settings",
      ),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (value) {
        // Ensure the selected index is within the range of items
        if (value < items.length) {
          onTap(value);
        }
      },
      backgroundColor: Colors.white,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      selectedIconTheme: IconThemeData(color: Colors.deepPurple),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
      showUnselectedLabels: true,
      selectedFontSize: 14,
      unselectedFontSize: 12,
      type: BottomNavigationBarType.fixed,
      items: items,
    );
  }
}

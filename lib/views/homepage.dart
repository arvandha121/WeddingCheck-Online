import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:weddingcheck/app/model/listItem.dart';
import 'package:weddingcheck/app/provider/provider.dart';
import 'package:weddingcheck/views/other/appbar/appbar.dart';
import 'package:weddingcheck/views/other/menu/bottomnavbar.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-child/homes.dart';
import 'package:weddingcheck/views/other/menu/screens/homes-parent/homes.dart';
import 'package:weddingcheck/views/other/menu/screens/management/management.dart';
import 'package:weddingcheck/views/other/menu/screens/scanner/qrscanner.dart';
import 'package:weddingcheck/views/other/menu/screens/settings/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ListItem> items = [];
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<UiProvider>(context).role;

    List<Widget> filteredWidgets = [
      Center(
        child: HomesParent(role: role),
      ),
      Center(
        child: QRScanner(),
      ),
      if (role == 'admin')
        Center(
          child: Management(),
        ),
      Center(
        child: Settings(),
      ),
    ];

    // Ensure the selected index is within the range of filteredWidgets
    if (selectedIndex >= filteredWidgets.length) {
      selectedIndex = 0;
    }

    return Scaffold(
      appBar: MyAppBar(role: role),
      body: filteredWidgets[selectedIndex],
      bottomNavigationBar: MyBottomNavBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        role: role,
      ),
    );
  }
}

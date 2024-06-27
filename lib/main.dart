import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:weddingcheck/app/provider/provider.dart';
import 'package:weddingcheck/views/auth/loginscreen.dart';
import 'package:weddingcheck/views/homepage.dart';
import 'package:weddingcheck/views/splashscreen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  if (await Permission.storage.request().isGranted) {
    // Izin diberikan
  } else {
    // Izin ditolak
  }

  if (await Permission.manageExternalStorage.request().isGranted) {
    // Izin diberikan
  } else {
    // Izin ditolak
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UiProvider()..initStorage(),
      child: Consumer<UiProvider>(
        builder: (
          context,
          UiProvider notifier,
          child,
        ) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              // Light theme settings
              brightness: Brightness.light,
              primaryColor: Colors.blue,
              scaffoldBackgroundColor: Colors.white,
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
              ),
            ),
            darkTheme: ThemeData(
              // Dark theme settings
              brightness: Brightness.dark,
              primaryColor: Colors.blueGrey,
              scaffoldBackgroundColor: Colors.black,
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),
            themeMode: notifier.darkMode ? ThemeMode.dark : ThemeMode.light,
            // if rememberme is true goto home and not show me login screen, otherwise go to login
            home: notifier.rememberMe ? const HomePage() : const Splash(),
          );
        },
      ),
    );
  }
}

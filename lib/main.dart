/*
 * File: main.dart
 * ----------------
 * Entry point for the Navidrome Rating App.
 * - Initializes Flutter and runs MyApp.
 * - Defines app theme and routes via InitialPage.
 * - InitialPage handles login status check and navigation to LoginPage or HomePage.
 */

// Import dart:async to access runZonedGuarded
import 'dart:async';
// Import Flutter core library for UI widgets
import 'package:flutter/material.dart';
// Import SharedPreferences for storing/retrieving login credentials
import 'package:shared_preferences/shared_preferences.dart';
// Import LoginPage widget to allow user authentication
import 'pages/login_page.dart';
// Import HomePage widget as the main application screen after login
import 'pages/home_page.dart';
// Import AppColors for consistent color scheme
import 'utils/app_colors.dart';
// Import LoggingService for error and log handling
import 'services/logging_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

// main() is the Dart VM entrypoint; runs before any widget is created
void main() async {
  // Ensure Flutter engine and bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize logging and create a new session file
  await LoggingService.init();
  // Initialize foreground background audio notifications
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.lokke.radio.esrating.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );
  // Run the app inside a zone that captures print() and errors
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      LoggingService.instance.logError(error, stack);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {
        // Preserve default behavior
        parent.print(zone, message);
        // Also write to our log file
        LoggingService.instance.log(message);
      },
    ),
  );
}

// MyApp sets up MaterialApp, theme, and initial route
class MyApp extends StatelessWidget {
  // Constant constructor for performance optimization
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp configures app-wide theme and navigation
    return MaterialApp(
      title: 'Navidrome Rating', // App title
      theme: ThemeData.dark().copyWith(
        // Use dark theme
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      // Initial screen that decides between login or home
      home: const InitialPage(),
    );
  }
}

// InitialPage checks saved credentials and navigates accordingly
class InitialPage extends StatelessWidget {
  const InitialPage({super.key}); // Default constructor

  // Private method to check if login credentials exist
  Future<bool> _checkLoginStatus() async {
    // Obtain shared preferences instance
    final prefs = await SharedPreferences.getInstance();
    // Retrieve stored username (null if not set)
    final username = prefs.getString('username');
    // Retrieve stored password (null if not set)
    final password = prefs.getString('password');
    // Return true only if both values are present
    return username != null && password != null;
  }

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to handle asynchronous credential check
    return FutureBuilder<bool>(
      future: _checkLoginStatus(), // Check login status
      builder: (context, snapshot) {
        // While waiting for the future, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If credentials exist, load HomePage
        if (snapshot.data == true) {
          // Retrieve shared preferences to get credentials
          final prefsFuture = SharedPreferences.getInstance();
          return FutureBuilder<SharedPreferences>(
            future: prefsFuture,
            builder: (context, prefsSnapshot) {
              // While retrieving prefs, show loading
              if (prefsSnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Extract username/password from prefs
              final prefs = prefsSnapshot.data!;
              final username = prefs.getString('username') ?? '';
              final password = prefs.getString('password') ?? '';
              // Navigate to HomePage with credentials and logout function
              return HomePage(
                username: username,
                password: password,
                onLogout: () {
                  // Remove stored credentials on logout
                  prefs.remove('username');
                  prefs.remove('password');
                  // Restart at InitialPage
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const InitialPage()),
                  );
                },
              );
            },
          );
        } else {
          // If not logged in, show LoginPage
          return LoginPage(
            onLogin: (username, password) {
              // On successful login, restart flow to show HomePage
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const InitialPage()),
              );
            },
          );
        }
      },
    );
  }
}

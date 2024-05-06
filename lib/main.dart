import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shop_cfast/screens/main_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import the Google Mobile Ads package
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging
import 'firebase_options.dart'; // Import your Firebase options file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler); // Setup background message handler
  final fcmToken = await FirebaseMessaging.instance.getToken();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  print("FCMToken $fcmToken");

  // Subscribe to a topic
  await FirebaseMessaging.instance.subscribeToTopic('cfast_push');
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulating a loading process. This can be replaced with your actual loading logic.
    // For demonstration, I'm using a Timer to simulate a 2-second delay.
    Timer(Duration(seconds: 2), () {
      setState(() {
        _isLoading =
            false; // Update isLoading to false to indicate loading is complete.
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cfast Classifieds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        textTheme: GoogleFonts.mulishTextTheme(),
      ),
      home: _isLoading ? const SplashScreen() : const MainScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Set background color to light grey
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your logo widget here
            Image.asset(
              'assets/logo.png', // Replace 'assets/logo.png' with your logo image path
              width: 150, // Adjust width as needed
              height: 150, // Adjust height as needed
              fit: BoxFit.contain, // Adjust fit as needed
            ),
            SizedBox(height: 50), // Spacer
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange), // Set progress indicator color to orange
            ),
          ],
        ),
      ),
    );
  }
}

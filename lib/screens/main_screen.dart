import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/screens/home_screen.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'MessageScreen2.dart';
import 'MessageScreen.dart';
import 'create_listing.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'saved_screen.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:badges/badges.dart' as badges;

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late SharedPreferences sharedPreferences;
  late SharedPreferences _prefs;
  late int unreadMessageCount;
  late ValueNotifier<int> unreadMessageCountNotifier;

  int currentTab = 0;
  List<Widget> screens = [
    HomeScreen(),
    SavedScreen(),
    HomeScreen(),
    MessageScreen2(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _initializeSharedPreferences();
    //unreadMessageCount = 0;
    unreadMessageCountNotifier = ValueNotifier<int>(0); // Initialize with 0
    //_loadUnreadMessageCount();
    Future.delayed(const Duration(milliseconds: 200), () {
      _loadUnreadMessageCount();
    });
    _startPeriodicFetch();
  }

  @override
  void dispose() {
    unreadMessageCountNotifier.dispose(); // Dispose the ValueNotifier
    super.dispose();
  }

  void _initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final token = sharedPreferences.getString("token");
      if (token != null) {
        final String url =
            '$baseUrl/cfastapi/getmessagescount.php?token=$token';

        print(url);

        final response = await http.get(
          Uri.parse(url),
        );
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          final List<dynamic> messages = jsonData['result']['data'];

          int unreadCount = 0;
          for (var message in messages) {
            if (message['p_is_unread'] == true) {
              unreadCount++;
            }
          }
          unreadMessageCountNotifier.value = unreadCount;

          // Save unread message count to SharedPreferences
          sharedPreferences.setInt('unreadCount', unreadCount);
        } else if (response.statusCode == 401) {
          // Token expired or unauthenticated
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Token expired or unauthenticated. Please login again.'),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login page and remove all routes from stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        } else {
          print('Failed to load unread message count: ${response.statusCode}');
        }
      } else {
        print('Token is null');
      }
    } catch (e) {
      print('Error loading unread message count: $e');
    }
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection, show a dialog or notification
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Internet Connection'),
            content: Text('Please connect to the internet and try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _startPeriodicFetch() async {
    // Load the unread message count immediately
    await _loadUnreadMessageCount();

    const period = Duration(minutes: 1);
    Timer.periodic(period, (timer) {
      _loadUnreadMessageCount(); // Call _loadUnreadMessageCount() every minute
    });
  }

  Future<void> _handleTabTap(int index) async {
    if (index != 0) {
      await checkLoginStatus();

      String status = sharedPreferences.getString("status") ?? "";

      if (status != "success") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      } else {
        setState(() {
          currentTab = index;
        });
      }
    } else {
      setState(() {
        currentTab = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if the current screen is the home screen
        bool isHomeScreen = currentTab == 0;

        if (isHomeScreen) {
          // If on the home screen, ask the user if they want to exit the app
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Exit App?'),
                    content: Text('Are you sure you want to exit the app?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Yes'),
                      ),
                    ],
                  );
                },
              ) ??
              false; // If the user dismisses the dialog, default to false
        } else {
          // If on a screen other than the home screen, switch to the home screen
          _handleTabTap(0);
          return false;
        }
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await checkLoginStatus();

            SharedPreferences sharedPreferences =
                await SharedPreferences.getInstance();
            String status = sharedPreferences.getString("status") ?? "";

            final token = sharedPreferences.getString("token");

            if (status != "success") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddListingScreen(), // Replace with AddListingScreen
                ),
              );
            }
          },
          backgroundColor: Colors.white,
          child: const Icon(
            Iconsax.add_circle,
            color: Colors.blue,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          height: 70,
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 5,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _handleTabTap(0), // Home tab
                icon: Icon(
                  Ionicons.grid_outline,
                  color: currentTab == 0 ? kprimaryColor : Colors.grey.shade400,
                ),
              ),
              IconButton(
                onPressed: () => _handleTabTap(1), // Wishlist tab
                icon: Icon(
                  Ionicons.heart_outline,
                  color: currentTab == 1 ? kprimaryColor : Colors.grey.shade400,
                ),
              ),
              IconButton(
                onPressed: () => _handleTabTap(3), // Chat tab
                icon: ValueListenableBuilder<int>(
                  valueListenable: unreadMessageCountNotifier,
                  builder: (context, count, _) {
                    return badges.Badge(
                      badgeContent: Text(
                        '$count',
                        style: TextStyle(color: Colors.white),
                      ),
                      child: Icon(
                        Icons.chat,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () => _handleTabTap(4), // Profile tab
                icon: Icon(
                  Ionicons.person_outline,
                  color: currentTab == 4 ? kprimaryColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        body: screens[currentTab],
      ),
    );
  }
}

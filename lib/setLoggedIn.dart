import 'package:shared_preferences/shared_preferences.dart';

// Storing user authentication status
Future<void> setLoggedIn(bool value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('isLoggedIn', value);
}

// Retrieving user authentication status
Future<bool> isLoggedIn() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

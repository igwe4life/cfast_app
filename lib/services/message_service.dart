import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';

class MessageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  static const String _unreadMessageCountKey = 'unreadMessageCount';
  int _unreadMessageCount = 0;

  int get unreadMessageCount => _unreadMessageCount;

  Future<void> fetchUnreadMessages() async {
    _prefs = await SharedPreferences.getInstance();
    String? token = _prefs.getString('token');
    final response = await http
        .get(Uri.parse('$baseUrl/cfastapi/getmessagescount.php?token=$token'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> messages = jsonData['result']['data'];

      int unreadCount = 0;
      for (var message in messages) {
        if (message['p_is_unread'] == true) {
          unreadCount++;
        }
      }

      _unreadMessageCount = unreadCount;
      _prefs.setInt(_unreadMessageCountKey, _unreadMessageCount);
      notifyListeners();
    } else {
      throw Exception('Failed to load unread messages');
    }
  }

  void startPolling() {
    fetchUnreadMessages(); // Initial fetch
    Timer.periodic(Duration(minutes: 1), (Timer timer) {
      fetchUnreadMessages(); // Fetch unread messages every 3 minutes
    });
  }
}

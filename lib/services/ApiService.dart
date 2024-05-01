import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final SharedPreferences _prefs;

  ApiService(this._prefs);

  Future<void> startChatThread(
      String name, String email, String body, int postId) async {
    final url = 'https://cfast.ng/cfastapi/start_chat.php';
    final String? token = _prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['auth_field'] = 'email';
    request.fields['email'] = email;
    request.fields['phone'] = 'phone'; // Add phone field if needed
    request.fields['phone_country'] = 'NG';
    request.fields['body'] = body;
    request.fields['post_id'] = postId.toString();

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    final decodedResponse = json.decode(responseBody);

    final threadId = decodedResponse['thread_id'] as int?;

    _prefs.setInt('post_$postId', threadId!);
  }

  Future<bool> checkChatStatus(int postId) async {
    final int? threadId = _prefs.getInt('post_$postId');
    return threadId != null;
  }

  Future<Map<String, dynamic>> startConversation(
      String name, String email, String body, int postId) async {
    final url = 'https://cfast.ng/api/threads';
    final String? token = _prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'X-AppApiToken': 'Uk1DSFlVUVhIRXpHbWt6d2pIZjlPTG15akRPN2tJTUs=',
      'X-AppType': 'docs',
    });
    request.fields.addAll({
      'name': name,
      'auth_field': 'email',
      'email': email,
      'body': body,
      'post_id': postId.toString(),
    });

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    final decodedResponse = json.decode(responseBody);

    return {
      'threadId': decodedResponse['thread_id'] as int?,
      'postTitle': decodedResponse['post_title'],
    };
  }

  Future<void> getThread(int threadId) async {
    final url = 'https://cfast.ng/api/threads/$threadId';
    final String? token = _prefs.getString('token');

    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'Uk1DSFlVUVhIRXpHbWt6d2pIZjlPTG15akRPN2tJTUs=',
          'X-AppType': 'docs',
        },
      );

      if (response.statusCode == 200) {
        print('Retrieved chat details');
        // Process the retrieved thread details as required
      } else {
        print('Error getting chat details');
      }
    } catch (e) {
      print('Exception occurred: $e');
    }
  }
}

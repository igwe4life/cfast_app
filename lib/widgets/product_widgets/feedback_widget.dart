import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeedbackWidget extends StatefulWidget {
  final String storeName;

  FeedbackWidget({Key? key, required this.storeName}) : super(key: key);

  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  late Future<Map<String, dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = fetchData();
  }

  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://cfast.ng/cfastapi/fetch_feedback.php?stname=${widget.storeName}'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error: $error');
      rethrow; // Rethrow the error to propagate it further
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data!;
          final List<dynamic> feedbackData = data['data'];
          final String message = data['message'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feedbackData.isNotEmpty)
                Center(
                  child: Text(
                    'Feedback about seller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              SizedBox(height: 5),
              Column(
                children: feedbackData.take(2).map((feedback) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(feedback['url']),
                    ),
                    title: Text(feedback['post_title']),
                    subtitle: Text(feedback['comment']),
                    trailing: Icon(Icons.arrow_forward),
                  );
                }).toList(),
              ),
              if (feedbackData.isEmpty)
                Center(
                  child: Text(
                    'No reviews available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                )
            ],
          );
        }
      },
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package for date formatting

class GetFeedbackScreen extends StatefulWidget {
  final String storeName;

  GetFeedbackScreen({required this.storeName});

  @override
  _GetFeedbackScreenState createState() => _GetFeedbackScreenState();
}

class _GetFeedbackScreenState extends State<GetFeedbackScreen> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://cfast.ng/cfastapi/fetch_feedback.php?stname=${widget.storeName}'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        records = List<Map<String, dynamic>>.from(responseData['data']);
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Feedback',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                // Parse and format the date
                DateTime date = DateTime.parse(records[index]['created_at']);
                String formattedDate =
                    DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);

                return Card(
                  margin: EdgeInsets.all(10.0),
                  child: ListTile(
                    leading: _getIcon(records[index]['rating']),
                    title: Text(
                      '${records[index]['post_title']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // SizedBox(height: 5.0),
                        // Text('Rating: ${records[index]['rating']}'),
                        SizedBox(height: 5.0),
                        Text('${records[index]['comment'] ?? 'No comment'}'),
                        SizedBox(height: 5.0),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 14.0, // Set the font size to 14
                            color: Colors
                                .grey[800], // Set the text color to dark grey
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Handle tap
                    },
                  ),
                );
              },
            ),
    );
  }

  Icon _getIcon(String rating) {
    switch (rating) {
      case '3':
        return Icon(Icons.thumbs_up_down, color: Colors.red, size: 50);
      case '1':
        return Icon(Icons.thumb_up_alt, color: Colors.green, size: 50);
      case '2':
        return Icon(Icons.thumb_down_alt, color: Colors.orange, size: 50);
      default:
        return Icon(Icons.error, color: Colors.green, size: 50);
    }
  }
}

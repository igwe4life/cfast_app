import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'edit_posts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiListViewScreen extends StatefulWidget {
  @override
  _ApiListViewScreenState createState() => _ApiListViewScreenState();
}

class _ApiListViewScreenState extends State<ApiListViewScreen> {
  late Future<List<dynamic>> _futureData;
  late int uid;
  // late String name;
  // late String email;
  // late String photoUrl;
  // late String phone;
  // late String token;

  @override
  void initState() {
    super.initState();
    loadAuthToken();
  }

  Future<void> loadAuthToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      uid = sharedPreferences.getInt("uid") ?? 0;
      // name = sharedPreferences.getString("name") ?? "Name";
      // email = sharedPreferences.getString("email") ?? "Email";
      // photoUrl = sharedPreferences.getString("photo_url") ?? "";
      // phone = sharedPreferences.getString("phone") ?? "Phone";
      // token = sharedPreferences.getString("token") ?? "token";
    });

    // Call fetchData() here after setting uid
    _futureData = fetchData();
  }

  Future<List<dynamic>> fetchData() async {
    // if (uid == null || uid == 0) {
    //   print('UID is null or invalid: $uid');
    //   Fluttertoast.showToast(msg: 'UID is null or invalid: $uid');
    //   return []; // Return empty list if UID is invalid
    // }

    final url = Uri.parse(
        'https://cfast.ng/cfastapi/fetch_saved_posts.php?user_id=$uid');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Text('No results found'),
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      final leadingText = (index + 1).toString();
                      DateTime date = DateTime.parse(item['created_at']);
                      String formattedDate =
                          DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPostScreen(item),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: Text(
                                leadingText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold, // Make the title bold
                              ),
                            ),
                            subtitle: Text(formattedDate),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

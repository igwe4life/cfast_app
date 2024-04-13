import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchesTab extends StatefulWidget {
  @override
  _SearchesTabState createState() => _SearchesTabState();
}

class _SearchesTabState extends State<SearchesTab> {
  late List<SavedSearch> savedSearches;
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    fetchSavedSearches();
  }

  Future<void> loadUserProfile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      uid = sharedPreferences.getInt("uid") ?? 0;
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
    });
  }

  Future<void> fetchSavedSearches() async {
    final apiUrl = 'https://cfast.ng/api/savedSearches';
    final queryParams = {
      'embed': 'null',
      'sort': 'created_at',
      'perPage': '100',
    };

    final response = await http.get(
      Uri.parse(
          '$apiUrl?${Uri(queryParameters: queryParams)}'), // Use Uri(queryParameters: queryParams)
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
        'X-AppType': 'docs',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> searchList = data['result']['data'];
      setState(() {
        savedSearches =
            searchList.map((search) => SavedSearch.fromJson(search)).toList();
      });
    } else {
      throw Exception('Failed to load saved searches');
    }
  }

  @override
  Widget build(BuildContext context) {
    return savedSearches != null
        ? ListView.builder(
            itemCount: savedSearches.length,
            itemBuilder: (context, index) {
              final search = savedSearches[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(search.keyword),
                  subtitle: Text('Count: ${search.count}'),
                ),
              );
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }
}

class SavedSearch {
  final int id;
  final String countryCode;
  final int userId;
  final String keyword;
  final String query;
  final int count;

  SavedSearch({
    required this.id,
    required this.countryCode,
    required this.userId,
    required this.keyword,
    required this.query,
    required this.count,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'],
      countryCode: json['country_code'],
      userId: json['user_id'],
      keyword: json['keyword'],
      query: json['query'],
      count: json['count'],
    );
  }
}

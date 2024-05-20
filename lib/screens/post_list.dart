import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class Post {
  final int id;
  final String title;
  final String description;
  final String contactName;
  final String email;
  final String phone;
  final String userPhotoUrl;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.userPhotoUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      contactName: json['contact_name'],
      email: json['email'],
      phone: json['phone'],
      userPhotoUrl: json['user_photo_url'],
    );
  }
}

class PostsListScreen extends StatefulWidget {
  @override
  _PostsListScreenState createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  late List<Post> _posts;

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
    fetchPosts();
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

  Future<void> fetchPosts() async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/api/posts?op=null&belongLoggedUser=1&embed=null&sort=created_at&perPage=100'),
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
      final jsonList = jsonDecode(response.body)['result']['data'];
      setState(() {
        _posts = jsonList.map<Post>((json) => Post.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts'),
      ),
      body: _posts == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  child: ListTile(
                    leading: post.userPhotoUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(post.userPhotoUrl),
                          )
                        : Icon(Icons.person),
                    title: Text(post.title),
                    subtitle: Text(post.description),
                    onTap: () {
                      // Navigate to post details screen or do something else
                    },
                  ),
                );
              },
            ),
    );
  }
}

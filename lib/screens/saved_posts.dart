import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_posts.dart';
import '../constants.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  _SavedPostsScreenState createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<dynamic> _savedPosts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
  }

  Future<void> _fetchSavedPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response =
          await http.get(Uri.parse('$baseUrl/cfastapi/fetch_saved_posts.php'));
      if (response.statusCode == 200) {
        setState(() {
          _savedPosts = json.decode(response.body);
        });
      } else {
        print('Failed to fetch saved posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching saved posts: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _savedPosts.length,
              itemBuilder: (context, index) {
                final post = _savedPosts[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditPostScreen(post)),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(post['title']),
                  subtitle: Text(
                      post['date'] ?? ''), // Assuming 'date' is a field in your data
                );
              },
            ),
    );
  }
}

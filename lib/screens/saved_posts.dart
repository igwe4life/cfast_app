import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class SavedPostsScreen extends StatefulWidget {
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
        title: Text('Saved Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(
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
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(post['title']),
                  subtitle: Text(
                      post['date']), // Assuming 'date' is a field in your data
                );
              },
            ),
    );
  }
}

class EditPostScreen extends StatefulWidget {
  final dynamic post;

  EditPostScreen(this.post);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  // Define controllers for editing post details
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _tagsController = TextEditingController();
  TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAuthToken();

    // Initialize controller values with post data
    _titleController.text = widget.post['title'];
    _descriptionController.text = widget.post['description'];
    _tagsController.text = widget.post['tags'];
    _priceController.text = widget.post['price'];
    // _categoryController.text = widget.post['category_id'];
    // _cityController.text = widget.post['city_id'];
  }

  Future<void> loadAuthToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _submitEditedPost();
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitEditedPost() async {
    // Prepare data to post
    var data = {
      'category_id': widget.post['category_id'].toString(),
      'package_id': '1',
      'country_code': 'NG',
      'email': email,
      'phone': phone,
      'phone_country': 'NG',
      'city_id': widget.post['city_id'].toString(),
      'auth_field': 'email',
      'contact_name': name,
      'admin_code': '0',
      'accept_terms': 'true', // boolean value represented as string
      'title': _titleController.text,
      'description': _descriptionController.text,
      'tags': _tagsController.text,
      'price': _priceController.text, // New field for price
    };

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/posts'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
    });

    // Add form fields
    request.fields.addAll(data);

    // Send multipart request
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        // Handle successful response
        print('Post updated successfully');
        // You can navigate back to previous screen or show a success message
      } else {
        // Handle error response
        print('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Exception while updating post: $e');
    }
  }
}

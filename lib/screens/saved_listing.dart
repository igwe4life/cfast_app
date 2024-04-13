import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewSavedPosts extends StatefulWidget {
  @override
  _ViewSavedPostsState createState() => _ViewSavedPostsState();
}

class _ViewSavedPostsState extends State<ViewSavedPosts> {
  List<Map<String, dynamic>> savedListings = [];

  @override
  void initState() {
    super.initState();
    loadSavedListings();
  }

  Future<void> loadSavedListings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedListingsString = prefs.getStringList('savedListings');
    if (savedListingsString != null) {
      setState(() {
        savedListings =
            savedListingsString.map<Map<String, dynamic>>((jsonString) {
          return json.decode(jsonString) as Map<String, dynamic>;
        }).toList();
      });
    }
  }

  String getCategoryName(int categoryId) {
    switch (categoryId) {
      case 1:
        return 'Vehicles';
      case 9:
        return 'Mobiles';
      case 14:
        return 'Electronics';
      case 30:
        return 'Furniture';
      case 37:
        return 'Property';
      case 46:
        return 'Pets';
      case 54:
        return 'Fashion';
      case 62:
        return 'Beauty';
      case 73:
        return 'Jobs';
      case 93:
        return 'Services';
      case 114:
        return 'Learning';
      case 122:
        return 'Events';
      // Add more cases for other category IDs if needed
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Listings'),
      ),
      body: ListView.builder(
        itemCount: savedListings.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> listing = savedListings[index];
          String title = listing['title'] ?? 'No Title';
          int categoryId = listing['selectedSubCategory'] ??
              0; // Assuming 0 for unknown category
          String categoryName = getCategoryName(categoryId);
          String date = listing['date'] ?? 'No Date';

          return ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Category: $categoryName',
                      style: TextStyle(
                        color: Colors.blue.shade900, // Adjust color as needed
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade900, // Adjust color as needed
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Implement navigation and submit logic here
            },
          );
        },
      ),
    );
  }
}

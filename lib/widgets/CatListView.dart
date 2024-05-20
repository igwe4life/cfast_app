import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screens/category_view.dart';
import 'SubCatList.dart';
import '../../constants.dart';

class Category {
  final int id;
  final int parent_id;
  final String name;
  final String slug;
  final String description;
  final String pictureUrl;

  Category({
    required this.id,
    required this.parent_id,
    required this.name,
    required this.slug,
    required this.description,
    required this.pictureUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      parent_id: json['parent_id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      pictureUrl: json['picture_url'] as String,
    );
  }
}

class CatListView extends StatefulWidget {
  final String? catname;
  final int catId;
  final int parentId;

  const CatListView({
    Key? key,
    required this.catname,
    required this.catId,
    required this.parentId,
  }) : super(key: key);

  @override
  _CatListViewState createState() => _CatListViewState();
}

class _CatListViewState extends State<CatListView> {
  List<Category> categories = [];
  bool isLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    initializeImageUrl();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void initializeImageUrl() {
    String aurl = '$baseUrl/api/categories?parentId=9';

    if (widget.catname?.contains('Vehicles') == true) {
      var catId = 1;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Mobiles') == true) {
      var catId = 9;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Electronics') == true) {
      var catId = 14;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Furniture') == true) {
      var catId = 30;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Property') == true) {
      var catId = 37;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Pets') == true) {
      var catId = 46;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Fashion') == true) {
      var catId = 54;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Beauty') == true) {
      var catId = 62;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Jobs') == true) {
      var catId = 73;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Services') == true) {
      var catId = 97;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Learning') == true) {
      var catId = 114;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else if (widget.catname?.contains('Events') == true) {
      var catId = 122;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    } else {
      var catId = 9;
      aurl = '$baseUrl/api/categories?parentId=$catId';
    }

    fetchCategories(aurl);
  }

  Future<void> fetchCategories(String aurl) async {
    setState(() {
      isLoading = true;
    });

    try {
      const Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppType': 'docs',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
      };

      final response = await http.get(Uri.parse(aurl), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final List<dynamic> data = responseData['result']['data'];
        final fetchedCategories = data
            .map((categoryData) => Category.fromJson(categoryData))
            .toList();

        setState(() {
          categories = fetchedCategories;
        });
      } else {
        print('Failed to fetch categories. Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to fetch categories. Error: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> searchApi(String query) async {
    const Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
    };

    // Construct the API endpoint with the search query
    String apiEndpoint = '$baseUrl/api/posts?op=search&q=$query';

    try {
      final response = await http.get(Uri.parse(apiEndpoint), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final List<dynamic> data = responseData['result']['data'];
        final fetchedCategories = data
            .map((categoryData) => Category.fromJson(categoryData))
            .toList();

        // Build a new ListView.builder with the fetched data
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Search Results'),
              content: SizedBox(
                height: 300, // Set the desired height
                child: ListView.builder(
                  itemCount: fetchedCategories.length,
                  itemBuilder: (BuildContext context, int index) {
                    final category = fetchedCategories[index];
                    return ListTile(
                      //title: Text(category.title),
                      subtitle: Text(category.description),
                      // Add other properties you want to display
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        print('Failed to fetch categories. Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to fetch categories. Error: $error');
    }
  }

  void search() {
    String searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      // Call the new searchApi method with the entered query
      searchApi(searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'I am looking for...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold, // Bold text
                    ),
                    onSubmitted: (value) {
                      search();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: Colors.blue,
                  onPressed: () {
                    search();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: Image.network(
                      category.pictureUrl,
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    // subtitle: const Text(
                    //   // category.description,
                    //   "234",
                    //   style: TextStyle(fontSize: 14.0),
                    // ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        // MaterialPageRoute(
                        //   builder: (context) => CatSubListView(
                        //     categoryName: category.name,
                        //     categorySlug: category.slug,
                        //     categoryParentId: category.parent_id,
                        //   ),
                        // ),
                        MaterialPageRoute(
                          builder: (context) => CategoryView(
                            catId: category.id,
                            parentId: category.parent_id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shop_example/models/product.dart';
import 'package:shop_example/screens/product_screen.dart';

import 'home_screen.dart';

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

class CategoryView extends StatefulWidget {
  final int catId;
  final int parentId;

  const CategoryView({Key? key, required this.catId, required this.parentId})
      : super(key: key);

  @override
  _CategoryViewState createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  late Future<List<Product>> _futureProducts;
  List<Category> categories = [];

  bool isLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _futureProducts = fetchDataFromApi(widget.catId, widget.parentId);
  }

  Future<List<Product>> fetchDataFromApi(int catId, int parentId) async {
    final response = await http.get(Uri.parse(
        'https://cfast.ng/cfastapi/catlist.php?catId=$catId&parent_id=$parentId'));

    if (response.statusCode == 200) {
      //

      final List<dynamic> jsonResponse = json.decode(response.body);

      List<Product> products = jsonResponse.map((item) {
        return Product(
          title: item['title'],
          description: item['title'],
          image: item['image'],
          price: item['price'],
          date: item['date'],
          time: item['time'],
          itemUrl: item['itemUrl'],
          classID: item['classID'],
          location: item['location'],
          catURL: item['catURL'],
        );
      }).toList();

      return products;
    } else {
      throw Exception('Failed to load data');
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
    String apiEndpoint = 'https://cfast.ng/api/posts?op=search&q=$query';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Product>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No classified Ads found for this category',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      child: Text('Go to Home Screen'),
                    ),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                child: StaggeredGridView.countBuilder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (_, index) {
                    return _buildGridItem(context, snapshot.data![index]);
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(product: product),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Color.fromARGB(255, 242, 245, 248),
          border: Border.all(
            color: Colors.black,
            width: 2.0,
          ),
        ),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: Image.network(
                  product.image,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.price.toString(),
                      style: Theme.of(context).textTheme.subtitle1!.merge(
                            const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                            ),
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle2!.merge(
                            TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 12,
                            ),
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product.location.toLowerCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle2!.merge(
                            TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

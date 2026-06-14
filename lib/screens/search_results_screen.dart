import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/models/product.dart'; // Import your Product model
import 'package:http/http.dart' as http;

import 'package:shop_cfast/screens/product_screen_brief.dart';

import '../constants.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<Product> products;
  final String query;

  const SearchResultsScreen({super.key, required this.products, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAuthToken();
  }
  final String _selectedLocation = 'Location';
  final String _selectedCategory = 'Category';
  final String _selectedPrice = 'Price';

  late SharedPreferences sharedPreferences;

  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  String token = '';

  Future<void> _performSearch(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on tap outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(), // Circular loading indicator
        );
      },
    );

    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/cfastapi/search.php?q=$query'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Content-Language': 'en',
            'X-AppType': 'docs',
            'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          },
        );

        // Hide loading indicator
        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          final Map<String, dynamic>? jsonResponse = json.decode(response.body);

          if (jsonResponse != null && jsonResponse.containsKey('listings')) {
            final List<dynamic> listings = jsonResponse['listings'];

            List<Product> products = listings.map((item) {
              return Product(
                title: item['title'] ?? '',
                description: item['title'] ?? '',
                image: item['image'] ?? '',
                price: item['price'] ?? '',
                date: item['date'] ?? '',
                time: item['time'] ?? '',
                itemUrl: item['url'] ?? '',
                classID: item['classID'] ?? '',
                location: item['location'] ?? '',
                catURL: item['url'] ??
                    '', // Assuming 'url' is the URL to the category
              );
            }).toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsScreen(
                  products: products,
                  query: query,
                ),
              ),
            );
          } else {
            // Handle API error
            print('API Error: Invalid response format');
            Fluttertoast.showToast(msg: 'API Error: Invalid response format');
          }
        } else {
          // Handle API error
          print('API Error: ${response.statusCode}');
          Fluttertoast.showToast(msg: 'API Error: ${response.statusCode}');
        }
      } catch (e) {
        // Hide loading indicator
        Navigator.of(context).pop();

        // Handle other errors
        print('Error: $e');
        Fluttertoast.showToast(msg: 'API Error 2: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        title: const Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter search term...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF3F6FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _performSearch(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Search',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Future<void> loadAuthToken() async {
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

  Widget _buildSearchResults() {
    String searchTerm = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Found ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      TextSpan(
                        text: '${widget.products.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const TextSpan(text: ' results for '),
                      TextSpan(
                        text: '"${widget.query}"',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: () {
                    _saveSearchQuery(widget.query, widget.products.length);
                  },
                  icon: const Icon(Icons.bookmark_border),
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              Product product = widget.products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductScreenBrief(product: product),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 110,
                          child: (product.image != null &&
                                  product.image.isNotEmpty)
                              ? Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[100],
                                    child: const Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.image_outlined,
                                      size: 32, color: Colors.grey),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product.price ?? 'Price not available',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.title ?? 'Title not available',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(
                                      product.location ??
                                          'Location not available',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveSearchQuery(String query, int searchResultsCount) async {
    // Make API call to save the search query
    // Adjust the URL and headers according to your API documentation
    const url = '$baseUrl/api/savedSearches';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: json.encode({
          'url':
              'https://cfast.ng/search/?q=$query&l=', // Adjust the URL format as needed
          'count_posts': searchResultsCount,
        }),
      );

      if (response.statusCode == 200) {
        // Display success message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search query saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        print('Search query saved successfully');
      } else {
        // Display error message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save search query'),
            backgroundColor: Colors.red,
          ),
        );
        // Handle error response
        print('Failed to save search query: ${response.body}');
      }
    } catch (e) {
      // Display error message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving search query: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Handle network or other errors
      print('Error saving search query: $e');
    }
  }

  void _performFilteredSearch() {
    // Implement your search logic with filters
    String searchTerm = _searchController.text.trim();
    String locationFilter =
        _selectedLocation == 'Location' ? '' : _selectedLocation;
    String categoryFilter =
        _selectedCategory == 'Category' ? '' : _selectedCategory;
    String priceFilter = _selectedPrice == 'Price' ? '' : _selectedPrice;

    // Implement API call or local search logic using filters
    // You can use these values to refine your search query
  }
}

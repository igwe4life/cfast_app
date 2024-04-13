import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shop_example/models/product.dart'; // Import your Product model
import 'package:http/http.dart' as http;

class SearchResultsScreen extends StatefulWidget {
  final List<Product> products;
  final String query;

  SearchResultsScreen({required this.products, required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Location';
  String _selectedCategory = 'Category';
  String _selectedPrice = 'Price';

  Future<void> _performSearch(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on tap outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Circular loading indicator
        );
      },
    );

    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('https://cfast.ng/cfastapi/search.php?q=$query'),
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
        Fluttertoast.showToast(msg: 'API Error 2: ${e}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter search term...',
                    ),
                  ),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    _performSearch(context);
                  },
                  child: Text('Go'),
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

  Widget _buildSearchResults() {
    String searchTerm = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Search results for ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${widget.query}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            )),
        Expanded(
          child: ListView.builder(
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              Product product = widget.products[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  contentPadding: EdgeInsets.all(8),
                  title: Text(
                    product.price,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        product.location,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                  ),
                  leading: Image.network(
                    product.image,
                    width: 100, // Set the desired width
                    height:
                        double.infinity, // Set the height to occupy full height
                    fit: BoxFit.cover, // Cover the container with the image
                    alignment:
                        Alignment.centerLeft, // Align the image to the left
                  ),
                  // Add more details or actions if needed
                ),
              );
            },
          ),
        ),
      ],
    );
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

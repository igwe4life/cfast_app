import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ionicons/ionicons.dart';
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/screens/search_results_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:shop_cfast/models/product.dart';

class SearchField extends StatefulWidget {
  const SearchField({Key? key}) : super(key: key);

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            color: kcontentColor,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 5,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                height: 25,
                width: 1.5,
                color: Colors.grey,
              ),
              IconButton(
                onPressed: () {
                  _performSearch(context);
                },
                icon: const Icon(
                  Ionicons.search,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // const SizedBox(height: 10),

        // Add the AdMob banner here
        // Container(
        //   height: 50,
        //   alignment: Alignment.center,
        //   // CustomBannerAd() can be added here
        // ),
      ],
    );
  }

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
            //Fluttertoast.showToast(msg: 'API Error: Invalid response format');
          }
        } else {
          // Handle API error
          print('API Error: ${response.statusCode}');
          //Fluttertoast.showToast(msg: 'API Error: ${response.statusCode}');
        }
      } catch (e) {
        // Hide loading indicator
        Navigator.of(context).pop();

        // Handle other errors
        print('Error: $e');
        //Fluttertoast.showToast(msg: 'API Error 2: ${e}');
      }
    }
  }
}

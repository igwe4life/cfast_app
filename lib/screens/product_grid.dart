import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProductGridState createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late Future<List<Map<String, dynamic>>> fetchData;

  @override
  void initState() {
    super.initState();
    fetchData = fetchProductsFromAPI();
  }

  Future<List<Map<String, dynamic>>> fetchProductsFromAPI() async {
    final response = await http.get(Uri.parse(
        'https://bworldapp.online/cfastapi/test.php')); // Replace with your API endpoint

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _showApiResponseSnackBar(response.body); // Display the API response
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load products');
    }
  }

  void _showApiResponseSnackBar(String response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Grid'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final productList = snapshot.data!;
            return _buildStaggeredGridView(productList);
          }
        },
      ),
    );
  }

  Widget _buildStaggeredGridView(List<Map<String, dynamic>> productList) {
    return StaggeredGridView.countBuilder(
      crossAxisCount: 2,
      itemCount: productList.length,
      itemBuilder: (BuildContext context, int index) {
        final product = productList[index];
        return _buildProductCard(product);
      },
      staggeredTileBuilder: (int index) =>
          StaggeredTile.fit(1), // Adjusts based on content
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        // Handle onTap action
      },
      child: Card(
        // Build your card UI using the product data
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product['image'],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['title']),
                  Text(product['price']),
                  // Add more widgets to display other product details
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

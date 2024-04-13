import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class ProductListing {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String price;
  final String pictureUrl;

  ProductListing({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    required this.pictureUrl,
  });

  factory ProductListing.fromJson(Map<String, dynamic> json) {
    return ProductListing(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'] ?? 'No description available',
      price: json['price'],
      pictureUrl: json['pictures'][0]['filename_url_big'],
    );
  }
}

class CatSubListView extends StatefulWidget {
  //final String category;
  final String categoryName;
  final String categorySlug;
  final int categoryParentId;

  // const CatSubListView({required this.category});
  const CatSubListView(
      {required this.categoryName,
      required this.categorySlug,
      required this.categoryParentId});

  @override
  _CatSubListViewState createState() => _CatSubListViewState();
}

class _CatSubListViewState extends State<CatSubListView> {
  List<ProductListing> productListingData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductListings();
  }

  Future<void> fetchProductListings() async {
    const url =
        'https://cfast.ng/api/posts?op=latest'; // Replace with your actual API endpoint

    const Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    final jsonData = json.decode(response.body);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      final data = jsonData['result']['data'];
      final List<ProductListing> listings = [];

      for (var item in data) {
        final productListing = ProductListing.fromJson(item);
        listings.add(productListing);
      }

      setState(() {
        productListingData = listings;
        isLoading = false; // Data fetching is complete
      });

      // Fluttertoast.showToast(
      //     msg:
      //         'This is my Parent ID: ${widget.categoryParentId} .Slug Name:  ${widget.categorySlug}');

      // Show a toast message with the fetched data count
      Fluttertoast.showToast(
        msg: 'Fetched ${listings.length} products',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
    } else {
      // Handle error scenario
      print('Failed to fetch product listings');
      setState(() {
        isLoading = false; // Data fetching is complete, even with error
      });

      // Show an error toast message
      Fluttertoast.showToast(
        msg: 'Failed to fetch product listings',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(), // Display circular loader while fetching data
            )
          : ListView.builder(
              itemCount: productListingData.length,
              itemBuilder: (context, index) {
                final productListing = productListingData[index];
                return Card(
                  child: ListTile(
                    leading: Image.network(
                        productListing.pictureUrl), // Leading image
                    title: Text(productListing.title),
                    subtitle: Text(productListing.price),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListingDetailsScreen(
                            productListing: productListing,
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

class ProductListingDetailsScreen extends StatelessWidget {
  final ProductListing productListing;

  const ProductListingDetailsScreen({required this.productListing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productListing.title),
      ),
      body: Column(
        children: [
          Image.network(productListing.pictureUrl),
          Text(productListing.title),
          Text(productListing.price),
          Text(productListing.slug),
          Text(productListing.description),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CatSubListView(
      categoryName: '',
      categorySlug: '',
      categoryParentId: 0,
    ),
  ));
}

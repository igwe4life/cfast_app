import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/screens/product_screen.dart';
import 'package:shop_cfast/screens/home_screen.dart';

class GridHome extends StatefulWidget {
  const GridHome({Key? key}) : super(key: key);

  @override
  _GridHomeState createState() => _GridHomeState();
}

class _GridHomeState extends State<GridHome> {
  late Future<List<Product>> _futureProducts;
  int _limit = 20;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _futureProducts = fetchDataFromApi();
  }

  Future<List<Product>> fetchDataFromApi() async {
    try {
      final response = await http.get(Uri.parse(
          'https://cfast.ng/cfastapi/homelist.php?limit=$_limit&offset=$_offset'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        List<Product> products = jsonResponse.map((item) {
          return Product(
            title: item['title'],
            description:
                item['title'], // Assuming description is the same as title
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
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Handle error
      throw Exception('Failed to load data: $e');
    }
  }

  // Method to load more products
  // Method to load more products
  Future<void> loadMoreProducts() async {
    final currentProducts = await _futureProducts;
    print('Current products length: ${currentProducts.length}');
    // Fluttertoast.showToast(
    //     msg: 'Current products length: ${currentProducts.length}');
    setState(() {
      _offset += currentProducts.length;
    });
    final moreProducts = await fetchDataFromApi();
    print('More products length: ${moreProducts.length}');
    // Fluttertoast.showToast(msg: 'More products length: ${moreProducts.length}');
    setState(() {
      _futureProducts = _futureProducts
          .then((currentProducts) => [...currentProducts, ...moreProducts]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Failed to load data: Please check your Internet connection and retry.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              // Widget for empty data
              );
        } else {
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                loadMoreProducts();
              }
              return false;
            },
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
    );
  }

  Widget _buildGridItem(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          // Check if product is not null
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductScreen(product: product),
            ),
          );
        } else {
          // Handle the case where product is null, such as showing a toast message
          Fluttertoast.showToast(
            msg: 'Product details are not available.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                child: FutureBuilder(
                  future: getImageSize(product.image),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error loading image');
                    }
                    final Size imageSize = snapshot.data as Size;
                    final aspectRatio = imageSize.width / imageSize.height;
                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Image.network(
                        product.image ?? '', // Ensure image URL is not null
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.price?.toString() ??
                          '', // Ensure price is not null
                      style: Theme.of(context).textTheme.subtitle1!.merge(
                            const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.blue,
                            ),
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      product.title ?? '', // Ensure title is not null
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
                      product.location?.toLowerCase() ??
                          '', // Ensure location is not null
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

  Future<Size> getImageSize(String imageUrl) async {
    final Completer<Size> completer = Completer<Size>();
    final Image image = Image.network(imageUrl);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ));
        },
      ),
    );
    return completer.future;
  }
}

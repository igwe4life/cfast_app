import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shop_example/models/product.dart';
import 'package:shop_example/screens/product_screen.dart';

class GridSimilar extends StatefulWidget {
  final String catURL;

  const GridSimilar({Key? key, required this.catURL}) : super(key: key);

  @override
  _GridSimilarState createState() => _GridSimilarState();
}

class _GridSimilarState extends State<GridSimilar> {
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = fetchDataFromApi(widget.catURL);
  }

  Future<List<Product>> fetchDataFromApi(String catURL) async {
    final response = await http.get(
        Uri.parse('https://cfast.ng/cfastapi/similarlist.php?catid=${catURL}'));

    if (response.statusCode == 200) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
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
                    _refreshData();
                  },
                  child: Text('Reload'),
                ),
              ],
            ),
          );
        } else {
          return StaggeredGridView.countBuilder(
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
          );
        }
      },
    );
  }

  Widget _buildGridItem(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductScreen(product: product)),
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

  void _refreshData() {
    setState(() {
      _futureProducts = fetchDataFromApi(widget.catURL);
    });
  }
}

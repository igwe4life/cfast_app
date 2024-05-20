import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this import
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/screens/profile_page.dart';
import 'package:shop_cfast/widgets/GridHome.dart';
import 'package:shop_cfast/widgets/categories.dart';
import 'package:shop_cfast/widgets/home_appbar.dart';
import 'package:shop_cfast/widgets/search_field.dart';
import 'package:shop_cfast/widgets/trending_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> products;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
    products = fetchProductsFromAPI();
  }

  Future<void> loadUserProfile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      name = sharedPreferences.getString("name") ?? "User";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
    });
  }

  Future<List<Product>> fetchProductsFromAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.get('$baseUrl/cfastapi/homelist.php' as Uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      List<Product> products = [];

      for (var item in data) {
        final product = Product(
          title: item['title'],
          description: item['description'],
          image: item['image'],
          price: item['price'],
          date: item['date'],
          time: item['time'],
          itemUrl: item['itemUrl'],
          classID: item['classID'],
          location: item['location'],
          catURL: item['catURL'],
        );

        products.add(product);
      }

      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<ConnectivityResult> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      body: SafeArea(
        child: FutureBuilder<ConnectivityResult>(
          future: checkConnectivity(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Future is still running
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              // Future completed with an error
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            } else if (snapshot.data == ConnectivityResult.none) {
              // No internet connection
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 50, color: Colors.red),
                    Text("No Internet Connection"),
                  ],
                ),
              );
            } else {
              // Internet connection is available, display GridHome
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {},
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(15),
                            ),
                            // iconSize: 30,
                            icon: Image.asset(
                              'assets/logo.png',
                              //height: 35,
                              width: 120,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to the profile screen here
                              // You can use Navigator to navigate to the profile screen
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfilePage()));
                            },
                            child: Text(
                              'Welcome\n$name',
                              style: const TextStyle(
                                fontSize: 14,
                                color: kprimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SearchField(),
                      const SizedBox(height: 20),
                      const Categories(),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(
                              "Trending",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // TextButton(
                          //   onPressed: () {},
                          //   child: const Text("See all"),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const GridHome(),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

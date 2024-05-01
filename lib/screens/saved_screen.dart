import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shop_example/models/product.dart'; // Import your Product model
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import 'package:shop_example/screens/product_screen_brief.dart';

class SavedScreen extends StatefulWidget {
  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;
  late Future<List<SavedSearch>> _fetchData;
  late Future<List<Ad>> _fetchAds;

  Future<void> loadUserProfile() async {
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

  @override
  void initState() {
    super.initState();
    loadUserProfile().then((_) {
      _fetchData = fetchSavedSearches(token);
      _fetchAds = fetchAds(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints.expand(height: 50),
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.blueAccent,
                tabs: [
                  Tab(text: 'Ads'),
                  Tab(text: 'Searches'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder<List<Ad>>(
                    future: _fetchAds,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerList();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading ads'),
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: Text('No ads saved!'),
                        );
                      } else {
                        return AdsTab(ads: snapshot.data!);
                      }
                    },
                  ),
                  FutureBuilder<List<SavedSearch>>(
                    future: _fetchData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerList();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading data'),
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: Text('No searches saved!'),
                        );
                      } else {
                        return SearchesTab(savedSearches: snapshot.data!);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5, // Number of shimmering list items
        itemBuilder: (BuildContext context, int index) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              title: Container(
                height: 20,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 20,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}

List<SavedSearch> savedSearches = [];

Future<List<Ad>> fetchAds(token) async {
  final apiUrl = 'https://cfast.ng/cfastapi/saved_posts.php?token=$token';

  final response = await http.get(
    Uri.parse(apiUrl),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((ad) => Ad.fromJson(ad)).toList();
  } else {
    throw Exception('Failed to load ads');
  }
}

Future<List<SavedSearch>> fetchSavedSearches(token) async {
  final apiUrl = 'https://cfast.ng/api/savedSearches';
  final tkk = '293|IfbUsq2eVrwVEsE8UDXiwRPgZIsDDy933KZJcr92';
  final queryParams = {
    'embed': 'null',
    'sort': 'created_at',
    'perPage': '100',
    'token': token,
  };

  final response = await http.get(
    Uri.parse('$apiUrl?${Uri(queryParameters: queryParams)}'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
      'X-AppType': 'docs',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> searchList = data['result']['data'];
    return searchList.map((search) => SavedSearch.fromJson(search)).toList();
  } else {
    throw Exception('Failed to load saved searches');
  }
}

class SearchesTab extends StatelessWidget {
  final List<SavedSearch> savedSearches;

  const SearchesTab({Key? key, required this.savedSearches}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: savedSearches.length,
      itemBuilder: (context, index) {
        final search = savedSearches[index];
        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(search.keyword),
            subtitle: Text('Search count: ${search.count}'),
          ),
        );
      },
    );
  }
}

class SavedSearch {
  final int id;
  final String countryCode;
  final int userId;
  final String keyword;
  final String query;
  final int count;

  SavedSearch({
    required this.id,
    required this.countryCode,
    required this.userId,
    required this.keyword,
    required this.query,
    required this.count,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'],
      countryCode: json['country_code'],
      userId: json['user_id'],
      keyword: json['keyword'],
      query: json['query'],
      count: json['count'],
    );
  }
}

class AdsTab extends StatelessWidget {
  final List<Ad> ads;

  const AdsTab({Key? key, required this.ads}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        final product = ad.toProduct(); // Convert Ad to Product

        DateTime date = DateTime.parse(ad.createdAt);
        String formattedDate =
            DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);

        // Format price with commas
        final priceFormat = NumberFormat("#,##0", "en_US");
        String formattedPrice =
            '₦${priceFormat.format(double.parse(ad.price))}';

        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: SizedBox(
              width: 64, // Specify desired width
              height: 64, // Specify desired height
              child: Image.network(
                product.image,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              product.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedPrice,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(formattedDate),
              ],
            ),
            // onTap: () {
            //   // Add onTap here
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => ProductScreenBrief(product: product)),
            //   );
            // },
          ),
        );
      },
    );
  }
}

class Ad {
  final int postId;
  final int? userId;
  final int categoryId;
  final String title;
  final String price;
  final String contactName;
  final String email;
  final String phone;
  final String createdAt;
  final String userPhotoUrl;
  final String? photoUrl;

  Ad({
    required this.postId,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.price,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.userPhotoUrl,
    required this.photoUrl,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      postId: json['post_id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      title: json['title'],
      price: json['price'],
      contactName: json['contact_name'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['created_at'],
      userPhotoUrl: json['user_photo_url'],
      photoUrl: json['photo_url'],
    );
  }

  Product toProduct() {
    return Product(
      title: title,
      description:
          '', // Add a default value or provide a description if available in Ad
      image: photoUrl ??
          '', // Use photoUrl if available, otherwise provide a default value
      price: price,
      date: createdAt,
      time: '', // Add a default value or provide a time if available in Ad
      itemUrl: '', // Add a default value or provide a URL if available in Ad
      classID: categoryId
          .toString(), // Convert categoryId to String and use it as classID
      location:
          '', // Add a default value or provide a location if available in Ad
      catURL: '', // Add a default value or provide a URL if available in Ad
    );
  }
}

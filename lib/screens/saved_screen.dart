import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/models/product.dart'; // Import your Product model
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import '../constants.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

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
  Future<List<SavedSearch>>? _fetchData;
  Future<List<Ad>>? _fetchAds;

  Future<void> loadUserProfile() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      uid = sharedPreferences.getInt("uid") ?? 0;
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
      
      // Fetch data after token is loaded
      _fetchData = fetchSavedSearches(token);
      _fetchAds = fetchAds(token);
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
              constraints: const BoxConstraints.expand(height: 50),
              child: const TabBar(
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
                        print('Ads error details: ${snapshot.error}'); // Debug print
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading ads: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _fetchAds = fetchAds(token);
                                  });
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
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
                        return const Center(
                          child: Text('Error loading data'),
                        );
                      } else if (snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return const Center(
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
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
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

Future<List<Ad>> fetchAds(String token) async {
  final apiUrl = '$baseUrl/cfastapi/saved_posts.php?token=$token';

  try {
    final response = await http.get(
      Uri.parse(apiUrl),
    );

    if (response.statusCode == 200) {
      final dynamic responseData = json.decode(response.body);

      // Handle if response is a string or already a List
      List<dynamic> data;
      if (responseData is String) {
        data = json.decode(responseData);
      } else if (responseData is List) {
        data = responseData;
      } else {
        data = [];
      }

      return data.map((ad) => Ad.fromJson(ad)).toList();
    } else {
      throw Exception('Failed to load ads: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching ads: $e');
    rethrow;
  }
}

Future<List<SavedSearch>> fetchSavedSearches(token) async {
  const apiUrl = '$baseUrl/api/savedSearches';
  const tkk = '293|IfbUsq2eVrwVEsE8UDXiwRPgZIsDDy933KZJcr92';
  final queryParams = {
    'embed': 'null',
    'sort': 'created_at',
    'perPage': '100',
    'token': token,
  };

  final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

  try {
    final response = await http.get(
      uri,
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
      print('Failed to load saved searches. Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      throw Exception('Failed to load saved searches');
    }
  } catch (e) {
    print('Error fetching saved searches: $e');
    rethrow;
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
          margin: const EdgeInsets.all(8.0),
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
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: SizedBox(
              width: 64, // Specify desired width
              height: 64, // Specify desired height
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    )
                  : const Icon(Icons.image), // Placeholder for missing image
            ),
            title: Text(
              product.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedPrice,
                  style: const TextStyle(
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
      postId: int.tryParse(json['post_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()),
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      price: json['price'].toString(),
      contactName: json['contact_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] ?? '',
      userPhotoUrl: json['user_photo_url'] ?? '',
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

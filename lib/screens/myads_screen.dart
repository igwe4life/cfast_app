import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import '../constants.dart';

class AdScreen extends StatefulWidget {
  const AdScreen({super.key});

  @override
  _AdScreenState createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;
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
    _fetchAds = _loadAndFetchAds();
  }

  Future<List<Ad>> _loadAndFetchAds() async {
    await loadUserProfile();
    return fetchAds(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Ads',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Ad>>(
        future: _fetchAds,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          } else if (snapshot.hasError) {
            // Show the actual error message for debugging
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading ads: ${snapshot.error}'),
                  const SizedBox(height: 16),
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
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No ads posted!'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final ad = snapshot.data![index];
                DateTime date = DateTime.parse(ad.createdAt);
                String formattedDate =
                    DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);
                // Format price with commas
                final priceFormat = NumberFormat("#,##0", "en_US");
                String formattedPrice = '₦${priceFormat.format(double.parse(ad.price))}';
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: Image.network(
                        ad.userPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      ad.title,
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
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: SizedBox(
              width: 64,
              height: 64,
              child: Container(
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
          );
        },
      ),
    );
  }
}

Future<List<Ad>> fetchAds(token) async {
  final apiUrl = '$baseUrl/cfastapi/my_ads.php?token=$token';
  
  try {
    print('Fetching ads from: $apiUrl');
    
    final response = await http.get(
      Uri.parse(apiUrl),
    ).timeout(const Duration(seconds: 30));
    
    print('Response status code: ${response.statusCode}');
    print('Response body length: ${response.body.length}');
    
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        print('Response body is empty');
        return [];
      }
      
      final decoded = json.decode(response.body);
      print('Decoded type: ${decoded.runtimeType}');
      
      List<dynamic> data;
      
      // Handle different response formats
      if (decoded is List) {
        data = decoded;
        print('Response is a List with ${data.length} items');
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List;
        print('Response is a Map with data field containing ${data.length} items');
      } else if (decoded is Map && decoded.containsKey('error')) {
        throw Exception(decoded['error']);
      } else {
        print('Unexpected response format: $decoded');
        return [];
      }
      
      if (data.isEmpty) {
        print('No ads found');
        return [];
      }
      
      final ads = data.map((ad) => Ad.fromJson(ad)).toList();
      print('Successfully parsed ${ads.length} ads');
      return ads;
      
    } else {
      print('HTTP Error: ${response.statusCode}');
      throw Exception('Failed to load ads: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('Exception in fetchAds: $e');
    throw Exception('Error loading ads: $e');
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
      postId: json['post_id'] is int ? json['post_id'] : int.tryParse(json['post_id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
      title: json['title'] ?? '',
      price: json['price']?.toString() ?? '0',
      contactName: json['contact_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] ?? '',
      userPhotoUrl: json['user_photo_url'] ?? '',
      photoUrl: json['photo_url'] ?? '',
    );
  }
}
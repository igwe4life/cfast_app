import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import '../constants.dart';

class AdScreen extends StatefulWidget {
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
    loadUserProfile().then((_) {
      _fetchAds = fetchAds(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
            return Center(
              child: Text('Error loading ads'),
            );
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
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
                String formattedPrice =
                    '₦${priceFormat.format(double.parse(ad.price))}';
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: SizedBox(
                      width: 64, // Specify desired width
                      height: 64, // Specify desired height
                      child: Image.network(
                        ad.userPhotoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      ad.title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        itemCount: 5, // Number of shimmering list items
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: SizedBox(
              width: 64, // Specify desired width
              height: 64, // Specify desired height
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
}

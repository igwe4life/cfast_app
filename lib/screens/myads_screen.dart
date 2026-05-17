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

  Future<void> _refreshAds() async {
    setState(() {
      _fetchAds = _loadAndFetchAds();
    });
  }

  /// Returns the image URL to display for the ad.
  /// Prefers user_photo_url (listing thumbnail) since photo_url is often empty.
  String _getAdImageUrl(Ad ad) {
    if (ad.userPhotoUrl.isNotEmpty) {
      return ad.userPhotoUrl;
    }
    if (ad.photoUrl != null && ad.photoUrl!.isNotEmpty) {
      return ad.photoUrl!;
    }
    return '';
  }

  /// Formats the date in a readable way, e.g. "Aug 3, 2025"
  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// Formats price with Naira symbol and commas
  String _formatPrice(String priceStr) {
    try {
      final priceFormat = NumberFormat("#,##0", "en_US");
      double price = double.parse(priceStr);
      return '₦${priceFormat.format(price)}';
    } catch (e) {
      return '₦$priceStr';
    }
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
            return _buildErrorView(snapshot.error.toString());
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            return _buildAdsList(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildAdsList(List<Ad> ads) {
    return RefreshIndicator(
      onRefresh: _refreshAds,
      color: Colors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          final imageUrl = _getAdImageUrl(ad);
          final formattedDate = _formatDate(ad.createdAt);
          final formattedPrice = _formatPrice(ad.price);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section
                  SizedBox(
                    width: 110,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Content section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ad.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E3E5C),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedPrice,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ads posted yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your listings will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading ads',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _fetchAds = _loadAndFetchAds();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 110,
                  height: 90,
                  color: Colors.white,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 130,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<List<Ad>> fetchAds(token) async {
  // Use Uri.https to properly encode the token (contains | character)
  final uri = Uri.https('cfast.ng', '/public/cfastapi/my_ads.php', {'token': token});
  
  try {
    print('Fetching ads from: $uri');
    
    final response = await http.get(
      uri,
    ).timeout(const Duration(seconds: 60));
    
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
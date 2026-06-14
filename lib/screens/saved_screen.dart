import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/models/product.dart'; // Import your Product model
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import '../constants.dart';
import 'package:shop_cfast/screens/product_screen.dart';
import 'package:shop_cfast/screens/search_results_screen.dart';

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
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints.expand(height: 50),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: Color(0xFF1D4ED8),
                unselectedLabelColor: Color(0xFF9CA3AF),
                indicatorColor: Color(0xFF1D4ED8),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D4ED8).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bookmark_outline,
                                    size: 40, color: Color(0xFF1D4ED8)),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No ads saved',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ads you save will appear here',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D4ED8).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_rounded,
                                    size: 40, color: Color(0xFF1D4ED8)),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No searches saved',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your saved searches will appear here',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 14,
                          width: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 120,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: savedSearches.length,
      itemBuilder: (context, index) {
        final search = savedSearches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Color(0xFF1D4ED8), size: 22),
            ),
            title: Text(
              search.keyword,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF111827),
              ),
            ),
            subtitle: Text(
              '${search.count} results',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            trailing: Icon(Icons.chevron_right,
                color: Colors.grey[400], size: 20),
            onTap: () async {
              final query = search.keyword;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                final response = await http.get(
                  Uri.parse('$baseUrl/cfastapi/search.php?q=$query'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Content-Language': 'en',
                    'X-AppType': 'docs',
                    'X-AppApiToken':
                        'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
                  },
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (response.statusCode == 200) {
                  final Map<String, dynamic>? jsonResponse =
                      json.decode(response.body);
                  if (jsonResponse != null &&
                      jsonResponse.containsKey('listings')) {
                    final List<dynamic> listings = jsonResponse['listings'];
                    List<Product> products = listings.map((item) {
                      return Product(
                        title: item['title'] ?? '',
                        description: item['title'] ?? '',
                        image: item['image'] ?? '',
                        price: item['price'] ?? '',
                        date: item['date'] ?? '',
                        time: item['time'] ?? '',
                        itemUrl: item['url'] ?? '',
                        classID: item['classID'] ?? '',
                        location: item['location'] ?? '',
                        catURL: item['url'] ?? '',
                      );
                    }).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(
                          products: products,
                          query: query,
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        final product = ad.toProduct();

        DateTime date = DateTime.tryParse(ad.createdAt) ?? DateTime.now();
        String formattedDate =
            DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);

        final priceFormat = NumberFormat("#,##0", "en_US");
        String formattedPrice =
            '₦${priceFormat.format(double.tryParse(ad.price) ?? 0)}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProductScreen(product: product)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 100,
                    child: product.image.isNotEmpty
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: const Icon(
                                    Icons.image_outlined,
                                    size: 32,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.image_outlined,
                                size: 32, color: Colors.grey),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
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
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
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
    String? bestPhotoUrl;
    if (json['listing_image'] != null) {
      bestPhotoUrl = json['listing_image'].toString();
    } else if (json['photo_url'] != null) {
      bestPhotoUrl = json['photo_url'].toString();
    } else if (json['pictures'] is List && (json['pictures'] as List).isNotEmpty) {
      final firstPic = (json['pictures'] as List)[0] as Map<String, dynamic>;
      bestPhotoUrl = (firstPic['filename_url_big'] ?? firstPic['filename_url'] ?? '').toString();
    }

    return Ad(
      postId: int.tryParse((json['post_id'] ?? json['id']).toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()),
      categoryId: int.tryParse((json['category_id'] ?? '').toString()) ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] ?? '0').toString(),
      contactName: json['contact_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] ?? '',
      userPhotoUrl: json['user_photo_url'] ?? '',
      photoUrl: bestPhotoUrl,
    );
  }

  Product toProduct() {
    return Product(
      title: title,
      description: '',
      image: photoUrl ?? '',
      price: price,
      date: createdAt,
      time: '',
      itemUrl: '',
      classID: postId.toString(),
      location: '',
      catURL: '',
    );
  }
}

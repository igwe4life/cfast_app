import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    // loadUserProfile();
    // _fetchData = fetchSavedSearches(token);
    // _fetchAds = fetchAds(token);
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
                        return Center(
                          child: CircularProgressIndicator(),
                        );
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
                        return Center(
                          child: CircularProgressIndicator(),
                        );
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
}

List<SavedSearch> savedSearches = [];

Future<List<Ad>> fetchAds(token) async {
  final apiUrl = 'https://cfast.ng/cfastapi/saved_posts.php?token=$token';

  // Fluttertoast.showToast(
  //   msg: 'Token code is: $token',
  //   toastLength: Toast.LENGTH_SHORT,
  //   gravity: ToastGravity.BOTTOM,
  //   timeInSecForIosWeb: 1,
  //   backgroundColor: Colors.grey,
  //   textColor: Colors.white,
  //   fontSize: 16.0,
  // );

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
            leading: Image.network(ad.userPhotoUrl),
            title: Text(
              ad.title,
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
}

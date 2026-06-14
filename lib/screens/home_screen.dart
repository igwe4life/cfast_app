import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/screens/profile_page.dart';
import 'package:shop_cfast/screens/search_results_screen.dart';
import 'package:shop_cfast/widgets/CustomBannerAd.dart';
import 'package:shop_cfast/widgets/GridHome.dart';
import 'package:shop_cfast/widgets/categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _powderBlueBorder = Color(0xFFB8D8F8);

  final ScrollController _scrollController = ScrollController();
  final GridHomeController _gridHomeController = GridHomeController();

  String name = "User";
  String email = "Email";
  String photoUrl = "";
  String phone = "Phone";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadUserProfile() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      name = sharedPreferences.getString("name") ?? "User";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
    });
  }

  Future<List<ConnectivityResult>> checkConnectivity() async {
    return Connectivity().checkConnectivity();
  }

  Future<void> _handleRefresh() async {
    await _gridHomeController.refresh();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.extentAfter < 700) {
      _gridHomeController.loadMoreIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Image.asset(
            'assets/logo.png',
            width: 120,
            alignment: Alignment.centerLeft,
          ),
        ),
        leadingWidth: 140,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _showSearchOverlay,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: _buildProfileAvatar(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<ConnectivityResult>>(
          future: checkConnectivity(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            if (snapshot.data!.contains(ConnectivityResult.none)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off_rounded, size: 50, color: Colors.red),
                    SizedBox(height: 8),
                    Text("No Internet Connection"),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: kprimaryColor,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildHeroHeader(context),
                          const SizedBox(height: 18),
                          _buildSectionCard(
                            child: const Categories(),
                          ),
                          const SizedBox(height: 14),
                          _buildAdCard(),
                          const SizedBox(height: 16),
                          _buildTrendingHeader(),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                  GridHome(controller: _gridHomeController),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final isValid = photoUrl.isNotEmpty &&
        !photoUrl.contains('default/user.png');
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: isValid ? NetworkImage(photoUrl) : null,
      child: isValid
          ? null
          : const Icon(Icons.person_outline, color: Colors.grey),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Welcome back, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    String? title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _powderBlueBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildAdCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Sponsored',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8),
          CustomBannerAd(),
        ],
      ),
    );
  }

  Widget _buildTrendingHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trending Listings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCE8FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Live feed',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kcontentColor,
                ),
                onSubmitted: (query) {
                  Navigator.pop(context);
                  _performSearch(query);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cfastapi/search.php?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppType': 'docs',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (response.statusCode == 200) {
        final Map<String, dynamic>? jsonResponse = json.decode(response.body);
        if (jsonResponse != null && jsonResponse.containsKey('listings')) {
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
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}

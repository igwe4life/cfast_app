import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/widgets/CustomBannerAd.dart';
import 'package:shop_cfast/widgets/GridSimilar.dart';
import 'package:shop_cfast/widgets/product_widgets/CallButtonsBar.dart';
import 'package:shop_cfast/widgets/product_widgets/ChatActionsWidget.dart';
import 'package:shop_cfast/widgets/product_widgets/information.dart';
import '../widgets/product_widgets/feedback_widget.dart';
import 'create_listing.dart';
import 'feedback_screen.dart';
import 'login_page.dart';

class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const Duration _productDetailsCacheTtl = Duration(minutes: 20);
  static final Map<String, _ProductDetailsCacheEntry> _productDetailsCache =
  <String, _ProductDetailsCacheEntry>{};

  bool _isLoading = false; // Loading indicator flag
  bool isLoading = false; // Add a boolean to track loading state

  bool isFavorite = false;
  bool isFavoriteLoading = false;

  bool addedToFavourites = false;

  final String apiUrl = 'https://cfast.ng/api/savedPosts';

  //final String url = '$baseUrl/getmessagescount.php?token=$token';

  final bool _isOfferLoading = false;
  late SharedPreferences sharedPreferences;

  int currentImage = 0;
  //bool isFavorite = false;
  Map<String, dynamic> productData = {};
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  List<String> imageUrls = [];

  // Declare variables for dropdown value and text field controller
  String dropdownValue1 = 'Choose Rating'; // Default dropdown value
  TextEditingController feedbackTextFieldController = TextEditingController();
  TextEditingController textEditingController = TextEditingController();

  String enteredOffer = ''; // Move outside the builder function

  @override
  void initState() {
    super.initState();
    phone = '';
    loadAuthToken();
    loadFavoriteStatus();
    fetchData();
  }

  @override
  void dispose() {
    feedbackTextFieldController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    Color? confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: confirmColor == null
                  ? null
                  : TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<bool> checkLoginStatus(BuildContext context) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
      return false; // User is not logged in
    }
    return true; // User is logged in
  }

  Future<void> loadAuthToken() async {
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

  Future<void> toggleFavorite() async {
    setState(() {
      isFavoriteLoading = true; // Start loading
    });

    // Store the favorite status in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool newFavoriteStatus = !isFavorite; // New favorite status to be set

    try {
      final response = newFavoriteStatus
          ? await http.post(
        Uri.parse('$baseUrl/api/savedPosts'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode(<String, dynamic>{
          'post_id': int.parse(widget.product.classID),
        }),
      )
          : await http.delete(
        Uri.parse('$baseUrl/api/savedPosts/${widget.product.classID}'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
      );

      if (response.statusCode == 200) {
        // Update local and shared preferences favorite status
        setState(() {
          isFavorite = newFavoriteStatus;
          isFavoriteLoading = false; // Stop loading
        });
        await prefs.setBool('isFavorite_${widget.product.classID}', isFavorite);
      } else {
        throw Exception('Failed to toggle favorite');
      }
    } catch (error) {
      print('Error: $error');
      // Revert back to the previous favorite status
      setState(() {
        isFavoriteLoading = false; // Stop loading
      });
      Fluttertoast.showToast(msg: 'Error toggling favorite');
    }
  }

  void loadFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorite =
          prefs.getBool('isFavorite_${widget.product.classID}') ?? false;
    });
  }

  // Method to provide feedback
  Future<void> _provideFeedback(String rating, String feedback) async {
    bool isLoggedIn = await checkLoginStatus(context);
    if (!isLoggedIn) return; // Return early if user is not logged in

    setState(() {
      _isLoading = true;
    });
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/cfastapi/provide_feedback.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          'rating': rating,
          'feedback': feedback,
          'product_id': widget.product.classID,
          'user_id': uid,
        }),
      );

      if (response.statusCode == 200) {
        // Request successful
        var responseBody = response.body;
        print('Response Body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Request failed
        print(
            'Failed to provide feedback. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to provide feedback. Status Code: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred during the request
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while providing feedback'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to report abuse
  Future<void> _reportAbuse(String dropdownValue, String text) async {
    bool isLoggedIn = await checkLoginStatus(context);
    if (!isLoggedIn) return; // Return early if user is not logged in

    setState(() {
      _isLoading = true;
    });
    // Add your logic to report abuse here
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/cfastapi/report_abuse.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          'comment': text,
          'rating': dropdownValue,
          'post_id': widget.product.classID,
          'user_id': uid,
        }),
      );

      if (response.statusCode == 200) {
        // Request successful
        var responseBody = response.body;
        print('Response Body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abuse reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Request failed
        print('Failed to report abuse. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to report abuse. Status Code: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred during the request
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to handle the request call button press
  Future<void> handleRequestCallPressed(BuildContext context) async {
    bool isLoggedIn = await checkLoginStatus(context);
    if (!isLoggedIn) return; // Return early if user is not logged in

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Call'),
          content: const Text('Are you sure you want to request a call?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog and make the request call
                Navigator.of(context).pop();
                requestCall();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Method to request a call
  Future<void> requestCall() async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/cfastapi/request_call.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          // Add any additional parameters required by the API
          'store_name': productData['StoreName'],
          'phone_number': productData['Phone'],
          'product_title': productData['Title'],
          'name': name,
          'phone': phone,
          'post_id': widget.product.classID,
          'user_id': uid,
          // You can add more parameters as needed
        }),
      );

      if (response.statusCode == 200) {
        // Request successful
        var responseBody = response.body;
        print('Response Body: $responseBody');
        // Fluttertoast.showToast(msg: 'Request for call sent successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request for callback sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Request failed
        print('Failed to request call. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to request callback. Status Code: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred during the request
      print('Error: $e');
      // Fluttertoast.showToast(msg: 'Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request callback. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to mark product as unavailable
  Future<void> _markProductUnavailable(productData) async {
    bool isLoggedIn = await checkLoginStatus(context);
    if (!isLoggedIn) return; // Return early if user is not logged in
    // Add your logic to mark product as unavailable here
    // Add your logic to report abuse here
    setState(() {
      _isLoading = true; // Show loading indicator before API call
    });

    try {
      var response = await http.post(
        Uri.parse('$baseUrl/cfastapi/post_status.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
        body: jsonEncode({
          'shop': productData,
          'current_url': 'https://cfast.ng',
          'post_id': widget.product.classID,
          'user_id': uid,
        }),
      );

      if (response.statusCode == 200) {
        // Request successful
        var responseBody = response.body;
        print('Response Body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product marked unavailable successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Request failed
        print(
            'Failed to mark product unavailable. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to mark product unavailable. Status Code: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error occurred during the request
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator after API call
      });
    }
  }

  // Fetch product data from the API
  Future<void> fetchData() async {
    final cacheKey = widget.product.classID;
    final cachedData = _productDetailsCache[cacheKey];
    if (cachedData != null && !cachedData.isExpired) {
      setState(() {
        productData = Map<String, dynamic>.from(cachedData.data);
        imageUrls = List<String>.from(cachedData.imageUrls);
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/posts/${widget.product.classID}?detailed=1'),
        headers: {
          'Accept': 'application/json',
          'Content-Language': 'en',
          'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
          'X-AppType': 'docs',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final result = decodedResponse['result'] as Map<String, dynamic>? ?? {};

        final mappedData = <String, dynamic>{
          'Title': result['title'] ?? '',
          'Description': result['description'] ?? '',
          'Price': (result['price'] ?? 0).toString(),
          'Phone': result['phone'] ?? '',
          'StoreName': result['contact_name'] ?? '',
          'StorePhoto': result['user_photo_url'] ?? '',
          'UserStatus': 'Online',
          'city_name': result['city_name'] ?? '',
          'created_at': result['created_at'] ?? '',
        };

        final pictures = result['pictures'] as List? ?? [];
        final urls = pictures.map<String>((p) {
          final pic = p as Map<String, dynamic>;
          return pic['filename_url_big']?.toString() ??
              pic['filename_url']?.toString() ??
              pic['filename_url_medium']?.toString() ??
              '';
        }).where((u) => u.isNotEmpty).toList();

        if (urls.isEmpty && result['listing_image'] != null) {
          urls.add(result['listing_image'].toString());
        }

        _productDetailsCache[cacheKey] =
            _ProductDetailsCacheEntry(result, DateTime.now(), urls);
        setState(() {
          productData = mappedData;
          imageUrls = urls;
        });
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during HTTP request: $e');
    }
  }

  // Remove hyperlinks from HTML string
  String removeHyperlinks(String htmlString) {
    return htmlString.replaceAllMapped(RegExp(r'<a[^>]*>.*?</a>'), (match) {
      final linkText = RegExp(r'>(.*?)<').firstMatch(match.group(0)!);
      return linkText?.group(1) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final processedHtml = removeHyperlinks(productData['Description'] ?? '');
    final sellerPhone = productData['Phone']?.toString() ?? '';
    final hasSellerActions = sellerPhone.isNotEmpty && sellerPhone != phone;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 360.0,
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                // flexibleSpace: FlexibleSpaceBar(
                //   background: Image.network(
                //     widget.product.image,
                //     fit: BoxFit.cover,
                //   ),
                // ),
                flexibleSpace: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _PremiumImageCarousel(
                  imageUrls: imageUrls,
                  currentIndex: currentImage,
                  onPageChanged: (index) {
                    currentImage = index;
                  },
                ),
                actions: [
                  // Favorite IconButton
                  // IconButton(
                  //   icon: Icon(
                  //     isFavorite ? Icons.favorite : Icons.favorite_border,
                  //     color: Colors.red,
                  //   ),
                  //   onPressed: toggleFavorite,
                  // ),
                  // if (isFavoriteLoading)
                  //   Positioned.fill(
                  //     child: Container(
                  //       color: Colors.black.withOpacity(0.5),
                  //       child: Center(
                  //         child: CircularProgressIndicator(),
                  //       ),
                  //     ),
                  //   ),
                  // Menu icon (3 dotted icon)
                  PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'feedback',
                        child: Text('Feedback'),
                      ),
                    ],
                    onSelected: (String value) {
                      // Handle the selected option
                      if (value == 'feedback') {
                        // Show AlertDialog for Feedback
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            // Build the AlertDialog content
                            return StatefulBuilder(
                              builder:
                                  (BuildContext context, StateSetter setState) {
                                return AlertDialog(
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/feedback.png', // Replace with your image path
                                        height: 64,
                                        width: 64,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Are you sure you want to give feedback this product or store?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: dropdownValue1,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            dropdownValue1 = newValue!;
                                          });
                                        },
                                        items: <String>[
                                          'Choose Rating',
                                          '5',
                                          '4',
                                          '3',
                                          '2',
                                          '1'
                                        ].map<DropdownMenuItem<String>>(
                                              (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                      TextField(
                                        controller: feedbackTextFieldController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your feedback here',
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Dismiss the dialog
                                      },
                                      child: const Text('Dismiss'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Call your API to provide feedback
                                        _provideFeedback(dropdownValue1,
                                            feedbackTextFieldController.text);
                                        Navigator.of(context)
                                            .pop(); // Dismiss the dialog
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
                floating: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _PremiumCard(
                        child: ProductInfo(
                          product: widget.product,
                          apiCityName: productData['city_name']?.toString(),
                          apiCreatedAt: productData['created_at']?.toString(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _ProductBannerAd(),
                      const SizedBox(height: 14),
                      _PremiumSectionCard(
                        title: 'Description',
                        icon: Icons.notes_rounded,
                        child: Html(
                          data: processedHtml.isEmpty
                              ? "Description not available yet."
                              : processedHtml,
                          style: {
                            "body": Style(
                              color: const Color(0xFF475569),
                              fontSize: FontSize(14.0),
                              lineHeight: const LineHeight(1.45),
                            ),
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (hasSellerActions)
                        CallButtonsBar(
                          onRequestCallPressed: () {
                            print('Request Call button pressed');
                            handleRequestCallPressed(
                                context); // Call the method to show the alert dialog
                          },
                          onMakeCallPressed: () async {
                            print('Make Call button pressed');
                            String nuphoneNumber = productData['Phone'];
                            final Uri telUri = Uri(
                              scheme: 'tel',
                              path: nuphoneNumber,
                            );

                            if (await canLaunchUrl(telUri)) {
                              await launchUrl(telUri);
                            } else {
                              throw 'Could not launch $telUri';
                            }
                          },
                          onWhatsappPressed: () {
                            print('Send Whatsapp Message');
                            String cphoneNumber = productData['Phone'];
                            print('Send Whatsapp Message: $cphoneNumber');
                            String msg =
                                'I\'m interested in your Ad listing ${productData['Title']} posted on CFAST.NG';

                            final Uri whatsapp = Uri.parse(
                                "https://wa.me/$cphoneNumber/?text=$msg");
                            // String url =
                            //     "https://wa.me/${cphoneNumber}/?text=${msg}";
                            // launch(url);
                            launchUrl(whatsapp);
                          },
                        ),
                      const SizedBox(height: 10),
                      if (hasSellerActions)
                        ChatActionsWidget(
                          title: "${productData['Title']}",
                          onMakeOfferPressed: () {
                            // Handle "Make an Offer" button press
                          },
                          onIsAvailablePressed: () {
                            // Handle "Is This Available" button press
                          },
                          onLastPricePressed: () {
                            // Handle "Last Price" button press
                          },
                          textEditingController: textEditingController,
                          onStartChatPressed: () {
                            // Handle "Start Chat" button press
                          },
                          postId: int.parse(widget
                              .product.classID), // Convert to int if necessary
                          price: "${productData['Price']}",
                          storeName: "${productData['StoreName']}",
                          phoneNumber: "${productData['Phone']}",
                          //firstImageUrl: imageUrls[0],
                          firstImageUrl:
                          "https://cfast.ng/storage/app/default/user.png",
                          product: widget.product,
                        ),
                      const SizedBox(height: 10),
                      _StoreDetailsCard(
                        storeName: productData['StoreName'] ?? 'Seller',
                        storeStatus:
                        productData['UserStatus'] ?? 'Status unavailable',
                        storePhoto: productData['StorePhoto'] ?? '',
                      ),
                      //FeedbackWidget(String productData['StoreName']),
                      const SizedBox(height: 14),
                      _PremiumSectionCard(
                        title: 'Seller reviews',
                        icon: Icons.verified_user_outlined,
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FeedbackScreen(
                                  productTitle: productData['Title'],
                                  storeName: productData['StoreName'],
                                ),
                              ),
                            );
                          },
                          child: const Text('Leave Feedback'),
                        ),
                        child: FeedbackWidget(
                          storeName: productData['StoreName'] ?? '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Html(
                      //   data: processedHtml ?? "Loading...",
                      //   style: {
                      //     "body": Style(
                      //       color: Colors.grey,
                      //       fontSize: FontSize(14.0),
                      //     ),
                      //   },
                      // ),
                      // const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                bool isLoggedIn =
                                await checkLoginStatus(context);
                                if (!isLoggedIn) {
                                  return; // Return early if user is not logged in
                                }
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/unavailable.png', // Replace with your image path
                                            height: 64,
                                            width: 64,
                                            fit: BoxFit.cover,
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Would you like to mark this product unavailable?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Dismiss the dialog
                                          },
                                          child: const Text('Dismiss'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Call your API to mark the product as unavailable
                                            // Replace the placeholder function call with your API call
                                            _markProductUnavailable(
                                                productData['StoreName']);
                                            Navigator.of(context)
                                                .pop(); // Dismiss the dialog
                                          },
                                          child: const Text('Mark'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                                side: WidgetStateProperty.all(BorderSide.none),
                                backgroundColor: WidgetStateProperty.all(
                                  const Color(0xFFEFF6FF),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 14),
                                ),
                                foregroundColor:
                                WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return Colors.blueAccent;
                                    }
                                    return const Color(0xFF1D4ED8);
                                  },
                                ),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    'Unavailable',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 8), // Add spacing between buttons
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                bool isLoggedIn =
                                await checkLoginStatus(context);
                                if (!isLoggedIn) {
                                  return; // Return early if user is not logged in
                                }
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    String dropdownValue =
                                        'Choose Rating'; // Default dropdown value
                                    TextEditingController textFieldController =
                                    TextEditingController(); // Controller for text field
                                    return StatefulBuilder(
                                      builder: (BuildContext context,
                                          StateSetter setState) {
                                        return AlertDialog(
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'assets/report.png', // Replace with your image path
                                                height: 64,
                                                width: 64,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'Are you sure you want to report this product or store?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              DropdownButton<String>(
                                                value: dropdownValue,
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    dropdownValue = newValue!;
                                                  });
                                                },
                                                items: <String>[
                                                  'Choose Rating',
                                                  '5',
                                                  '4',
                                                  '3',
                                                  '2',
                                                  '1'
                                                ].map<DropdownMenuItem<String>>(
                                                        (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(value),
                                                      );
                                                    }).toList(),
                                              ),
                                              TextField(
                                                controller: textFieldController,
                                                decoration:
                                                const InputDecoration(
                                                  hintText:
                                                  'Enter your reason here',
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Dismiss the dialog
                                              },
                                              child: const Text('Dismiss'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final confirmed =
                                                await _showConfirmationDialog(
                                                  title: 'Report abuse?',
                                                  message:
                                                  'Please confirm you want to submit this abuse report.',
                                                  confirmText: 'Submit report',
                                                  confirmColor: Colors.red,
                                                );
                                                if (!confirmed) return;

                                                // Call your API to report abuse
                                                _reportAbuse(dropdownValue,
                                                    textFieldController.text);
                                                Navigator.of(context)
                                                    .pop(); // Dismiss the dialog
                                              },
                                              child: const Text('Report'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                                side: WidgetStateProperty.all(BorderSide.none),
                                backgroundColor: WidgetStateProperty.all(
                                  const Color(0xFFFEF2F2),
                                ),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 14),
                                ),
                                foregroundColor:
                                WidgetStateProperty.resolveWith(
                                      (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return Colors.redAccent;
                                    }
                                    return const Color(0xFFDC2626);
                                  },
                                ),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, size: 18),
                                  SizedBox(height: 4),
                                  Text(
                                    'Report Abuse',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final confirmed = await _showConfirmationDialog(
                            title: 'Post a similar ad?',
                            message:
                            'This will open the listing form so you can create a new ad like this one.',
                            confirmText: 'Continue',
                          );
                          if (!confirmed) return;

                          // Handle 'Post ad like this' button press
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const AddListingScreen(), // Replace with AddListingScreen
                            ),
                          );
                        },
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                          side: WidgetStateProperty.all(BorderSide.none),
                          foregroundColor: WidgetStateProperty.resolveWith(
                                (states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.greenAccent;
                              }
                              return Colors.white;
                            },
                          ),
                          backgroundColor:
                          WidgetStateProperty.all(const Color(0xFF0F172A)),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_business_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Post ad like this',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      //const SizedBox(height: 60),
                      const SizedBox(height: 14),
                      _PremiumSectionCard(
                        title: 'Similar Ads',
                        icon: Icons.grid_view_rounded,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        child: GridSimilar(
                          key: PageStorageKey<String>(
                            'similar-${widget.product.catURL}-${widget.product.classID}',
                          ),
                          catURL: widget.product.catURL,
                          productId: widget.product.classID,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () {
          toggleFavorite();
        },
        child: isFavoriteLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        )
            : Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      ),
    );
  }
}

class _ProductDetailsCacheEntry {
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final List<String> imageUrls;

  const _ProductDetailsCacheEntry(this.data, this.cachedAt, this.imageUrls);

  bool get isExpired =>
      DateTime.now().difference(cachedAt) >
          _ProductScreenState._productDetailsCacheTtl;
}

class _PremiumImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PremiumImageCarousel({
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  State<_PremiumImageCarousel> createState() => _PremiumImageCarouselState();
}

class _PremiumImageCarouselState extends State<_PremiumImageCarousel> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant _PremiumImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.imageUrls
        .where((imageUrl) => imageUrl.trim().isNotEmpty)
        .toList();

    if (displayImages.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 56,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
            ),
          ),
        ),
        CarouselSlider.builder(
          itemCount: displayImages.length,
          options: CarouselOptions(
            height: 360.0,
            viewportFraction: 0.86,
            initialPage: 0,
            enableInfiniteScroll: displayImages.length > 1,
            autoPlay: displayImages.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeOutCubic,
            enlargeCenterPage: true,
            enlargeFactor: 0.22,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged(index);
            },
            scrollDirection: Axis.horizontal,
          ),
          itemBuilder: (context, index, realIndex) {
            final imageUrl = displayImages[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GalleryView(
                      images: displayImages,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(top: 78, bottom: 22),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              displayImages.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: index == _currentIndex ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const _PremiumSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StoreDetailsCard extends StatelessWidget {
  final String storeName;
  final String storeStatus;
  final String storePhoto;

  const _StoreDetailsCard({
    required this.storeName,
    required this.storeStatus,
    required this.storePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = storePhoto.trim().isNotEmpty;

    return _PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF22C55E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
              hasPhoto ? CachedNetworkImageProvider(storePhoto) : null,
              child: hasPhoto
                  ? null
                  : const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  storeStatus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Seller',
              style: TextStyle(
                color: Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBannerAd extends StatelessWidget {
  const _ProductBannerAd();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Advertisement',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const CustomBannerAd(),
        ],
      ),
    );
  }
}

class GalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const GalleryView(
      {super.key, required this.images, required this.initialIndex});

  @override
  _GalleryViewState createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_currentIndex + 1}/${widget.images.length}',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100, // Adjust the height as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex =
                          index; // Update _currentIndex with the correct index
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image(
                      image: CachedNetworkImageProvider(widget.images[index]),
                      width: 80, // Adjust thumbnail width as needed
                      height: 80, // Adjust thumbnail height as needed
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
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
import 'package:shop_cfast/widgets/GridHome.dart';
import 'package:shop_cfast/widgets/GridSimilar.dart';
import 'package:shop_cfast/widgets/product_widgets/CallButtonsBar.dart';
import 'package:shop_cfast/widgets/product_widgets/ChatActionsWidget.dart';
import 'package:shop_cfast/widgets/product_widgets/information_brief.dart';
import '../widgets/product_widgets/feedback_widget.dart';
import 'create_listing.dart';
import 'feedback_screen.dart';
import 'login_page.dart';
import '../services/product_storage.dart';

class ProductScreenBrief extends StatefulWidget {
  final Product product;

  const ProductScreenBrief({Key? key, required this.product}) : super(key: key);

  @override
  _ProductScreenBriefState createState() => _ProductScreenBriefState();
}

class _ProductScreenBriefState extends State<ProductScreenBrief> {
  bool _isLoading = false; // Loading indicator flag
  bool isLoading = false; // Add a boolean to track loading state

  bool isFavorite = false;
  bool isFavoriteLoading = false;

  bool addedToFavourites = false;

  Product? product;

  final String apiUrl = 'https://cfast.ng/api/savedPosts';

  late SharedPreferences sharedPreferences;

  int currentImage = 0;
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
    loadAuthToken();
    loadFavoriteStatus();
    fetchData();
    // Call fetchImageUrls method to retrieve image URLs
    fetchImageUrls();
    getProduct();
  }

  Future<void> getProduct() async {
    product = await ProductStorage.getProductByClassID(widget.product.classID);
    setState(() {}); // Update the UI to display the retrieved product
  }

  Future<void> fetchImageUrls() async {
    String purl = widget.product.itemUrl;

    setState(() {
      isLoading = true; // Set loading to true when starting to fetch data
    });

    try {
      var response = await http.get(
        Uri.parse('$baseUrl/cfastapi/get_images.php?purl=${purl}'),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        setState(() {
          imageUrls = List<String>.from(jsonData);
          isLoading = false; // Set loading to false after data is fetched
        });
      } else {
        print(
            'Failed to fetch image URLs. Status Code: ${response.statusCode}');
        setState(() {
          isLoading = false; // Set loading to false if there's an error
        });
      }
    } catch (e) {
      print('Error fetching image URLs: $e');
      setState(() {
        isLoading = false; // Set loading to false if there's an error
      });
    }
  }

  Future<bool> checkLoginStatus(BuildContext context) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
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
          SnackBar(
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
        SnackBar(
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
          SnackBar(
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
          title: Text('Request Call'),
          content: Text('Are you sure you want to request a call?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog and make the request call
                Navigator.of(context).pop();
                requestCall();
              },
              child: Text('Confirm'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          SnackBar(
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
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/cfastapi/post_details.php?pid=${widget.product.classID}'));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          productData = decodedResponse;
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

    if (_isLoading) {
      // Show loading indicator if API call is in progress
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // Show your main UI if API call is not in progress
      return Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  product!.image,
                  fit: BoxFit.cover,
                ),
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
                    PopupMenuItem<String>(
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
                                    SizedBox(height: 10),
                                    Text(
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
                                      decoration: InputDecoration(
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
                                    child: Text('Dismiss'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Call your API to provide feedback
                                      _provideFeedback(dropdownValue1,
                                          feedbackTextFieldController.text);
                                      Navigator.of(context)
                                          .pop(); // Dismiss the dialog
                                    },
                                    child: Text('Submit'),
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
              pinned: false,
              floating: true,
            ),
            SliverPadding(
              padding: EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    ProductInfo(product: widget.product),
                    Html(
                      data: processedHtml ?? "Loading...",
                      style: {
                        "body": Style(
                          color: Colors.grey,
                          fontSize: FontSize(14.0),
                        ),
                      },
                    ),
                    const SizedBox(height: 5),
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
                            "https://wa.me/${cphoneNumber}/?text=${msg}");
                        // String url =
                        //     "https://wa.me/${cphoneNumber}/?text=${msg}";
                        // launch(url);
                        launchUrl(whatsapp);
                      },
                    ),
                    const SizedBox(height: 5),
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
                      postId:
                          int.parse(widget.product.classID), // Convert to int
                      price: "${productData['Price']}",
                      storeName: "${productData['StoreName']}",
                      phoneNumber: "${productData['Phone']}",
                      product: widget.product,
                      firstImageUrl: imageUrls[0],
                      //product: widget.product.toString(),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light grey color
                        borderRadius:
                            BorderRadius.circular(10), // Rounded edges
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius:
                                    20, // Radius half of 40 to make it 40x40
                                backgroundImage: NetworkImage(imageUrls[0] ??
                                    "https://cfast.ng/storage/app/default/user.png"),
                              ),
                              SizedBox(
                                  width:
                                      5), // Adding space between image and text
                              Text(
                                productData['StoreName'] ?? "Loading...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(width: 45),
                              Text(
                                productData['UserStatus'] ?? "Loading...",
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    //FeedbackWidget(String productData['StoreName']),
                    FeedbackWidget(
                      storeName: productData['StoreName'] ?? '',
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(
                              //uid: uid,
                              productTitle: productData['Title'],
                              storeName: productData['StoreName'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // Border radius set to 10
                        ),
                      ),
                      child: Text('Leave Feedback'),
                    ),
                    const SizedBox(height: 5),
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
                              bool isLoggedIn = await checkLoginStatus(context);
                              if (!isLoggedIn)
                                return; // Return early if user is not logged in
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
                                        SizedBox(height: 10),
                                        Text(
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
                                        child: Text('Dismiss'),
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
                                        child: Text('Mark'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              side: MaterialStateProperty.all(
                                BorderSide(color: Colors.blue),
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.blueAccent;
                                  }
                                  return Colors.green;
                                },
                              ),
                            ),
                            child: Text(
                              'Mark \nUnavailable',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 8), // Add spacing between buttons
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              bool isLoggedIn = await checkLoginStatus(context);
                              if (!isLoggedIn)
                                return; // Return early if user is not logged in
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  String dropdownValue =
                                      'Rating'; // Default dropdown value
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
                                            SizedBox(height: 10),
                                            Text(
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
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                            ),
                                            TextField(
                                              controller: textFieldController,
                                              decoration: InputDecoration(
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
                                            child: Text('Dismiss'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Call your API to report abuse
                                              _reportAbuse(dropdownValue,
                                                  textFieldController.text);
                                              Navigator.of(context)
                                                  .pop(); // Dismiss the dialog
                                            },
                                            child: Text('Report'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              side: MaterialStateProperty.all(
                                BorderSide(color: Colors.red),
                              ),
                              foregroundColor:
                                  MaterialStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(MaterialState.pressed)) {
                                    return Colors.redAccent;
                                  }
                                  return Colors.red;
                                },
                              ),
                            ),
                            child: Text(
                              'Report \nAbuse',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        // Handle 'Post ad like this' button press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddListingScreen(), // Replace with AddListingScreen
                          ),
                        );
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        side: MaterialStateProperty.all(
                          BorderSide(color: Colors.green),
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith(
                          (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.greenAccent;
                            }
                            return Colors.blue;
                          },
                        ),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white),
                      ),
                      child: Text(
                        'Post ad like this',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            toggleFavorite();
          },
          label: isFavoriteLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(
                  isFavorite == null
                      ? 'Add to Favorite'
                      : (isFavorite ? 'Remove Favorite' : 'Mark Favorite'),
                ),
          icon: isFavoriteLoading
              ? SizedBox() // Hide icon while loading
              : Icon(isFavorite == null
                  ? Icons.favorite_border
                  : (isFavorite ? Icons.favorite : Icons.favorite_border)),
        ),
      );
    }
  }
}

class GalleryView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  GalleryView({required this.images, required this.initialIndex});

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
            style: TextStyle(color: Colors.white)),
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
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Container(
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
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
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

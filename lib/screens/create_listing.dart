import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/screens/saved_listing.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/models/package_model.dart';
import 'package:shop_cfast/screens/package_selection_screen.dart';
import '../constants.dart';
import 'package:shop_cfast/screens/login_page.dart';
import 'package:shop_cfast/screens/main_screen.dart';

// Helper class to store payment details
class PaymentInfo {
  final String reference;
  final double amount;
  PaymentInfo(this.reference, this.amount);
}

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _categories11 = [];
  List<dynamic> _lgas = [];

  List<dynamic> _subCategories = [];
  List<dynamic> _subCategories11 = [];

  final List<dynamic> _myState = [];
  final List<dynamic> _myCities = [];

  List data = [];
  final int _value = 1;

  final List<Map<String, dynamic>> _cities = [];

  int _currentPage = 1; // Track current page
  bool _isLoadingCities = false;
  late int uid;
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;
  bool _isLoading2 = false;

  String _selectedCategory = '';
  String _selectedCategory11 = '';
  String _selectedSubCategory = '';
  String _selectedSubCategory11 = 'City';
  final String _selectedState = 'State';
  final String _selectedSubCity = 'City';
  String _selectedCity = ''; // Define _selectedCity variable
  String _loadingMessage = ''; // Added for progress feedback


  // Dynamic form fields state variables
  String _selectedCondition = 'Brand New';
  String _selectedBrand = '';
  final TextEditingController _modelController = TextEditingController();

  File? _selectedImage;
  final List<File?> _selectedImages = [];


  
  // Persist selected package for retries
  Package? _savedSelectedPackage;

  // IAP Variables
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  late SharedPreferences sharedPreferences;


  @override
  void initState() {
    super.initState();
    // Initialize IAP Stream
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
       print('IAP Stream Error: $error');
    });


    loadAuthToken(); // Used to be _loadUserData
    loadCategories();
    loadStates();
  }

  // IAP Listener
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _showErrorDialog('Purchase Error', purchaseDetails.error?.message ?? 'Unknown error');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
           
           String productId = purchaseDetails.productID;
           print('IAP Success: $productId');
           
               if (_savedSelectedPackage != null) {
                setState(() {
                    // Calculate amount from saved package
                    double paidAmount = (double.parse(_savedSelectedPackage!.price) * 100).toDouble() / 100;
                    // Use transactionID or verificationData as reference
                    String ref = purchaseDetails.purchaseID ?? 'IAP_REF';
                    
                    _paidPackages[_savedSelectedPackage!.id] = PaymentInfo(ref, paidAmount);
                });
           } else {
               // Fallback: Use productId to find package ID? 
               // For now, error out if package is lost, though it shouldn't be.
               _showErrorDialog('Error', 'Package selection lost. Please contact support with this ID: ${purchaseDetails.purchaseID}');
           }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<void> _buyProduct(Package package) async {
    String productId = Platform.isIOS ? package.appleProductId : 'package_${package.id}'; // Use mapped ID for iOS
    
    bool available = await _inAppPurchase.isAvailable();
    if (!available) {
        _showErrorDialog('Store Error', 'In-App Purchases are not available.');
        return;
    }
    
    // Query Product
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
    
    if (response.notFoundIDs.isNotEmpty) {
        print('Product not found in App Store: $productId - IAP Product Not Found: ${response.notFoundIDs.join(', ')}');
        _showErrorDialog('Product Error', 'Product $productId not found in App Store.');
        return;
    }
    
    if (response.productDetails.isEmpty) {
        _showErrorDialog('Product Error', 'No product details found.');
        return;
    }
    
    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  getData() async {
    final res = await http
        .get(Uri.parse("$baseUrl/cfastapi/get_cities.php?parentId=909"));
    setState(() {
      data = jsonDecode(res.body);
    });
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

  Future<void> loadCategories() async {
    String jsonString = await loadCategoriesData();
    setState(() {
      _categories = json.decode(jsonString)['strippedData'];
    });
  }

  Future<String> loadCategoriesData() async {
    return await rootBundle.loadString('assets/categories.json');
  }

  Future<void> loadStates() async {
    try {
      String jsonString = await loadStatesData();
      setState(() {
        _categories11 = json.decode(jsonString)['strippedData'];
      });
    } catch (e) {
      print('Exception while loading states: $e');
    }
  }

  Future<String> loadStatesData() async {
    return await rootBundle.loadString('assets/states.json');
  }

  Future<void> loadLGA(String lga) async {
    try {
      String jsonString = await loadLGAData();
      setState(() {
        _lgas = json.decode(jsonString)['strippedData'];
      });
    } catch (e) {
      print('Exception while loading states: $e');
    }
  }

  Future<String> loadLGAData() async {
    return await rootBundle.loadString('assets/data/abia.json');
  }

  Future<void> loadSubCategories(int parentId) async {
    String apiUrl =
        '$baseUrl/api/categories?parentId=$parentId&nestedIncluded=0';

    try {
      var response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppType': 'docs',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
      });
      if (response.statusCode == 200) {
        setState(() {
          _subCategories = json.decode(response.body)['result']['data'];
          _selectedSubCategory = _subCategories.isNotEmpty
              ? _subCategories[0]['id'].toString()
              : 'No Subcategory';
        });
      } else {
        print('Failed to load subcategories');
      }
    } catch (e) {
      print('Exception while loading subcategories: $e');
    }
  }

  Future<void> loadSubCities(String statecode) async {
    //Fluttertoast.showToast(msg: 'And we\'re inside the cities');

    String apiUrl = '$baseUrl/cfastapi/get_cities.php?statecode=$statecode';

    try {
      var response = await http.get(Uri.parse(apiUrl), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Language': 'en',
        'X-AppType': 'docs',
        'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
      });
      if (response.statusCode == 200) {
        //Fluttertoast.showToast(msg: response.body);
        setState(() {
          _subCategories11 = json.decode(response.body)['result']['data'];
          _selectedSubCategory11 = _subCategories11.isNotEmpty
              ? _subCategories11[0]['id'].toString()
              : 'No Subcategory';
        });
      } else {
        print('Failed to load sub cities');
        //Fluttertoast.showToast(msg: 'Failed to load sub cities');
      }
    } catch (e) {
      print('Exception while loading sub cities: $e');
      //Fluttertoast.showToast(msg: 'Exception while loading sub cities: $e');
    }
  }

  // Removed loadCities as it is redundant and slow. 
  // Cities are loaded dynamically via loadSubCities when a state is selected.


  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildOutlinedDropdownButton({
    required List<DropdownMenuItem<String>> items,
    required String value,
    required ValueChanged<String?> onChanged,
    required String labelText,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          if (_selectedImages[index] != null) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Stack(
                children: [
                   Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8.0),
                       image: DecorationImage(
                         image: FileImage(_selectedImages[index]!),
                         fit: BoxFit.cover,
                       ),
                     ),
                   ),
                   Positioned(
                     right: 0,
                     top: 0,
                     child: GestureDetector(
                       onTap: () {
                          // Show a dialog to confirm deletion
                         showDialog(
                           context: context,
                           builder: (BuildContext context) {
                             return AlertDialog(
                               title: const Text('Delete Image'),
                               content: const Text(
                                   'Are you sure you want to delete this image?'),
                               actions: [
                                 TextButton(
                                   onPressed: () {
                                     Navigator.of(context).pop(); // Close the dialog
                                   },
                                   child: const Text('Cancel'),
                                 ),
                                 TextButton(
                                   onPressed: () {
                                     setState(() {
                                       _selectedImages.removeAt(index);
                                        // Also keep null placeholders if needed or just remove from list. 
                                        // The original code used a fixed list size initially but then added/removed. 
                                        // Based on usage, just removing the itme is safer if it's dynamic.
                                     });
                                     Navigator.of(context).pop(); // Close the dialog
                                   },
                                   child: const Text('Delete'),
                                 ),
                               ],
                             );
                           },
                         );
                       },
                       child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle
                          ),
                         child: const Icon(
                           Icons.delete,
                           size: 24,
                           color: Colors.red,
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Future<void> saveListing() async {
    // Show loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      List<String>? savedListings = prefs.getStringList('savedListings') ?? [];

      // Get the current date
      DateTime currentDate = DateTime.now();
      String formattedDate =
          currentDate.toString(); // You can format the date as needed

      // Add the current listing details to the saved list
      savedListings.add(json.encode({
        'date': formattedDate,
        'selectedSubCategory': _selectedSubCategory,
        'selectedCity': _selectedCity,
        'contact_name': name,
        'email': email,
        'phone': phone,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'tags': _tagsController.text,
        'price': _priceController.text,
        // Add other fields as needed
      }));

      Fluttertoast.showToast(
          msg: 'Listing saved inside SharedPreferences: $savedListings');

      // Save the updated list back to SharedPreferences
      await prefs.setStringList('savedListings', savedListings);

      // Close loading dialog
      Navigator.pop(context);

      // Show Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Listing "${_titleController.text}" saved successfully'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to saved_listing.dart after a delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ViewSavedPosts()),
        );
      });
    } catch (error) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while saving the listing'),
          duration: Duration(seconds: 2),
        ),
      );

      print('Error saving listing: $error');
    }
  }

  void submitSavedListing() {
    int packageId = 0;
    if (_savedSelectedPackage != null) {
      packageId = _savedSelectedPackage!.id;
    }
    _performSaveListing(packageId);
  }

  void _performSaveListing(int packageId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/cfastapi/saveposts.php'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
    });

    // Get category ID from the selected subcategory
    var selectedSubCategoryId = _selectedSubCategory != 'SubCategory'
        ? _selectedSubCategory
        : '0'; // Replace with default value if needed

    final String uidString = uid.toString();

    // Add form fields
    request.fields.addAll({
      'category_id': selectedSubCategoryId!,
      'package_id': packageId.toString(),
      'country_code': 'NG',
      'email': email,
      'phone': phone,
      'user_id': uid.toString(),
      'phone_country': 'NG',
      'city_id': _selectedCity!,
      'auth_field': 'email',
      'contact_name': name,
      'admin_code': '0',
      'accept_terms': 'true', // boolean value represented as string
      'title': _titleController.text,
      'description': _descriptionController.text,
      'tags': _tagsController.text,
      'price': _priceController.text, // New field for price
    });

    // Add image file
    for (File? image in _selectedImages) {
      if (image != null) {
        var imageField =
            await http.MultipartFile.fromPath('pictures[]', image.path);
        request.files.add(imageField);
      }
    }

    try {
      print('Sending Listing Request...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      // Dismiss loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        var decodedResponse = json.decode(responseBody);
        if (decodedResponse['success'] == true) {
          Fluttertoast.showToast(msg: decodedResponse['message']);
          Navigator.of(context).pop(); 
        } else {
          _showErrorDialog('Submission Failed', decodedResponse['message'] ?? responseBody);
        }
      } else {
         _showErrorDialog('Server Error (${response.statusCode})', responseBody);
      }
    } catch (e) {
      print('Exception: $e');
      // Dismiss loading dialog
      Navigator.of(context).pop();
      _showErrorDialog('Exception', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _recordPayment(int packageId, int postId, String transactionId, double amount) async {
      try {
        var url = Uri.parse('$baseUrl/cfastapi/insert_payments.php');
        
        // Determine payment method ID
        int paymentMethodId = Platform.isIOS ? 10 : 9; // 10 for iOS, 9 for Paystack

        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'amount': amount,
            'payment_method_id': paymentMethodId,
            'transaction_id': transactionId,
            'post_id': postId,
            'package_id': packageId,
            'active': 1
          }),
        );
        print('Payment Record Status: ${response.statusCode}');
        print('Payment Record Body: ${response.body}');
      } catch (e) {
        print('Error recording payment: $e');
      }
  }

  String _getReference() {
    var platform = (Platform.isIOS) ? 'iOS' : 'Android';
    final thisDate = DateTime.now().millisecondsSinceEpoch;
    return 'ChargedFrom${platform}_$thisDate';
  }

  // Stores paid package ID -> PaymentInfo
  Map<int, PaymentInfo> _paidPackages = {};

  void _handlePayment(Package package) {
    // Check if already paid for this session
    if (_paidPackages.containsKey(package.id)) {
       print('Package ${package.id} already paid. Proceeding to post listing.');
       _postListing(package.id);
       return;
    }

    if (Platform.isIOS) {
        _buyProduct(package);
    } else {
        _payWithPaystack(package);
    }
  }

  void _payWithPaystack(Package package) async {
    try {
      // Amount in kobo
      int amount = (double.parse(package.price) * 100).toInt();
      


      PaystackFlutter paystackFlutter = PaystackFlutter();
      
      paystackFlutter.pay(
        context: context, 
        secretKey: PAYSTACK_SECRET_KEY, 
        callbackUrl: 'https://standard.paystack.co/close', 

        email: email,
        amount: (double.parse(package.price) * 100).toDouble(), // Corrected: price * 100 for kobo
        // transactionRef: _getReference(), // Not supported in this package version?
        onCancelled: (paystackCallback) {
          Fluttertoast.showToast(msg: 'Payment cancelled');
        },
        onSuccess: (paystackCallback) {
          print('Payment Successful. Ref: ${paystackCallback.reference}');
          
          // Mark as paid with reference and amount
          setState(() {
            double paidAmount = (double.parse(package.price) * 100).toDouble() / 100; // Original amount
            _paidPackages[package.id] = PaymentInfo(paystackCallback.reference, paidAmount);
          });
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Payment failed: $e');
    }
  }

  bool _isReadyToSubmit() {
    if (_savedSelectedPackage == null) return false;
    if (_savedSelectedPackage!.price == '0.00' || _savedSelectedPackage!.price == '0') return true;
    return _paidPackages.containsKey(_savedSelectedPackage!.id);
  }

  void _handleNext() {
    print('DEBUG _handleNext: called');
    
    // Form validation
    bool isFormValid = _formKey.currentState?.validate() ?? false;
    print('DEBUG _handleNext: form valid = $isFormValid');
    
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Category validation
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // City validation
    if (_selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Image Validation
    bool hasImage = false;
    for (var img in _selectedImages) {
       if (img != null) {
         hasImage = true;
         if (img.lengthSync() > 2500 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 2.5MB'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            return;
         }
       }
    }
    
    print('DEBUG _handleNext: hasImage = $hasImage, images count = ${_selectedImages.where((img) => img != null).length}');
    
    if (!hasImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one image'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
    }

    print('DEBUG _handleNext: All validation passed, showing package dialog');
    
    showDialog(
       context: context,
       builder: (dialogContext) => PackageSelectionScreen(
         token: token,
         onPackageSelected: (package) {
           Navigator.of(dialogContext).pop(); // Close dialog
           print('DEBUG _handleNext: Package selected: ${package.name}, price: ${package.price}');
           // If free package (price is 0 or "Free")
           if (package.price == '0.00' || package.price == '0') {
               setState(() {
                 _savedSelectedPackage = package;
               });
               // Automatically submit for free packages
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Free package selected. Tap Submit to post your ad.'),
                   backgroundColor: Colors.green,
                   duration: Duration(seconds: 2),
                 ),
               );
           } else {
               setState(() {
                 _savedSelectedPackage = package;
               });
               _handlePayment(package);
           }
         },
       ),
    );
  }

  void submitListing() {
    if (_savedSelectedPackage != null) {
      _postListing(_savedSelectedPackage!.id);
    }
  }

  void _postListing(int packageId) async {
    setState(() {
      _isLoading = true; // Use main loading state
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/posts'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
    });

    // Get category ID from the selected subcategory
    var selectedSubCategoryId = _selectedSubCategory != 'SubCategory'
        ? _selectedSubCategory
        : '0'; // Replace with default value if needed

    // Add form fields
    request.fields.addAll({
      'category_id': selectedSubCategoryId,
      'package_id': packageId.toString(),
      'country_code': 'NG',
      'email': email,
      'phone': phone,
      'phone_country': 'NG',
      'city_id': _selectedCity,
      'auth_field': 'email',
      'contact_name': name,
      'admin_code': '0',
      'accept_terms': 'true', // boolean value represented as string
      'title': _titleController.text,
      'description': _descriptionController.text,
      'tags': _tagsController.text,
      'price': _priceController.text, // New field for price
    });

    // Add image file
    for (File? image in _selectedImages) {
      if (image != null) {
        var imageField =
            await http.MultipartFile.fromPath('pictures[]', image.path);
        request.files.add(imageField);
      }
    }

    try {
      print('Sending Listing Request...');
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        var decodedResponse = json.decode(responseBody);
        
        if (decodedResponse['success'] == true) {
           Fluttertoast.showToast(msg: decodedResponse['message']);
           
           // DEBUG: Print full response struct to help verify ID location
           print('DEBUG: Decoded Response: $decodedResponse');

           // Check for post_id in "result" or "data" or "id"
           int? postId;
           if (decodedResponse.containsKey('result') && decodedResponse['result'] is Map && decodedResponse['result'].containsKey('id')) {
              postId = int.tryParse(decodedResponse['result']['id'].toString());
           } else if (decodedResponse.containsKey('id')) {
              postId = int.tryParse(decodedResponse['id'].toString());
           } else if (decodedResponse.containsKey('data') && decodedResponse['data'] is Map && decodedResponse['data'].containsKey('id')) {
              // Also check 'data' key just in case
              postId = int.tryParse(decodedResponse['data']['id'].toString());
           }

           print('DEBUG: Parsed postId: $postId');
           print('DEBUG: checking _paidPackages[$packageId]: ${_paidPackages[packageId]}');

           // If payment was made, record it
           // Check if we have a payment info for this package
           if (_paidPackages.containsKey(packageId) && postId != null) {
               PaymentInfo info = _paidPackages[packageId]!;
               print('DEBUG: Recording payment with Ref: ${info.reference}, Amount: ${info.amount} ...');
               await _recordPayment(packageId, postId, info.reference, info.amount);
           } else {
               print('DEBUG: Skipping payment record. Condition failed.');
           }

           // Navigate to Home immediately, removing all previous routes
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (context) => const MainScreen()),
             (Route<dynamic> route) => false,
           );
        } else {
           // Failure case: Close processing dialog if open
           // Ideally we should differentiate between the processing dialog and the page
           // For now, if we are here, we might want to stay on page or just show toast
           // But if the processing dialog is up (barrierDismissible=false), we MUST pop it
           if (Navigator.canPop(context)) Navigator.pop(context);
           // Parse specific errors
           String errorMessage = decodedResponse['message'] ?? responseBody;
           if (decodedResponse.containsKey('errors')) {
              var errors = decodedResponse['errors'];
              if (errors is Map) {
                  // Check for pictures errors
                  List<String> picErrors = [];
                  errors.forEach((key, value) {
                      if (key.toString().contains('pictures') && value is List) {
                          picErrors.addAll(value.map((e) => e.toString()));
                      }
                  });
                  if (picErrors.isNotEmpty) {
                      errorMessage = "Image Upload Error:\n${picErrors.join('\n')}\n\nPlease reduce image size or try another image.";
                  }
              }
           }
          _showErrorDialog('Submission Failed', errorMessage);
        }
      } else {
         _showErrorDialog('Server Error (${response.statusCode})', responseBody);
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog('Exception', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> isImageScreenshot(File imageFile) async {
    // Get the filename of the image
    String filename = imageFile.path.split('/').last.toLowerCase();

    // Get the directory name of the image
    String directoryName = imageFile.parent.path.split('/').last.toLowerCase();

    // Check if the filename or directory name contains common patterns indicative of screenshot filenames
    if (filename.contains('screenshot') ||
        filename.contains('screen') ||
        filename.contains('capture') ||
        directoryName == 'screenshot' ||
        directoryName == 'screenshots') {
      return true; // It's likely a screenshot
    } else {
      return false; // It's not a screenshot
    }
  }

  Set<String> uploadedFiles = {}; // Maintain a set of uploaded file paths

  Future<void> addImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isEmpty) return;

    setState(() => _loadingMessage = 'Preparing images...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 20),
                Text(
                  _loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );

    int processedCount = 0;
    int totalCount = images.length;
    List<File> newlyProcessed = [];

    try {
      // Process all images in parallel for maximum speed
      await Future.wait(images.map((image) async {
        File file = File(image.path);
        
        bool isScreenshot = await isImageScreenshot(file);
        if (isScreenshot) return;

        if (uploadedFiles.contains(image.path)) return;

        final decodedImage = await decodeImageFromList(await file.readAsBytes());
        
        if (decodedImage.width > 400) {
          File watermarkedImage = await _addWatermarkToImages(file);
          
          newlyProcessed.add(watermarkedImage);
          uploadedFiles.add(image.path);
          
          processedCount++;
          // Use setState for progress only
          setState(() {
            _loadingMessage = 'Processed $processedCount of $totalCount images...';
          });
        }
      }));

      // Add all processed images at once to avoid list fragmentation and redundant builds
      if (newlyProcessed.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(newlyProcessed);
        });
      }
    } catch (e) {
      print('Error in addImages: $e');
    } finally {
      Navigator.pop(context);
      setState(() => _loadingMessage = '');
    }
  }

  Future<File> _addWatermarkToImages(File imageFile) async {
    try {
      // Read image bytes
      Uint8List imageBytes = await imageFile.readAsBytes();
      // Create an image object from bytes
      ui.Image image = await decodeImageFromList(imageBytes);
      // Create a blank image to draw on
      ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas canvas = ui.Canvas(recorder);
      // Draw the original image on the canvas
      canvas.drawImage(image, Offset.zero, Paint());
      // Define watermark text
      String watermarkText = '$name\n Posted on Cfast.NG';
      // Calculate scaling factor for font size based on image dimensions
      double scaleFactor = 1.0;
      if (image.width <= 640) {
        scaleFactor = 0.8;
      } else if (image.width >= 641 && image.width <= 1024) {
        scaleFactor = 1.0;
      } else if (image.width >= 1025 && image.width <= 1900) {
        scaleFactor = 1.25;
      } else if (image.width >= 1920 && image.width <= 2048) {
        scaleFactor = 2.25;
      } else if (image.width >= 2048 && image.width <= 3072) {
        scaleFactor = 3.25;
      } else if (image.width > 3072) {
        scaleFactor = 4.5;
      }

      // Calculate font size based on the scaling factor
      double fontSize = 50.0 * scaleFactor;
      // Define text style with calculated font size
      ui.TextStyle textStyle = ui.TextStyle(
        color: Colors.white.withOpacity(0.3), // Set opacity to 30%
        fontSize: fontSize, // Font size based on image dimensions
        fontWeight: ui.FontWeight.bold, // Customize font weight if needed
      );
      // Create ParagraphBuilder to build text layout
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontWeight: FontWeight.bold,
        fontSize: fontSize, // Same as the calculated font size
      ));
      // Add text to ParagraphBuilder
      builder.pushStyle(textStyle);
      builder.addText(watermarkText);
      // Build the Paragraph
      ui.Paragraph paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: image.width.toDouble()));
      // Calculate the Y offset to position the watermark 25% from the bottom
      double yOffset = image.height * 0.75 - paragraph.height;
      // Draw text on canvas with the adjusted Y offset
      canvas.drawParagraph(
        paragraph,
        Offset(
          (image.width - paragraph.width) / 2,
          yOffset,
        ),
      );
      // Convert the canvas to an image
      ui.Image watermarkedImage = await recorder.endRecording().toImage(
            image.width,
            image.height,
          );
      // Convert image to byte data
      ByteData? byteData = await watermarkedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      // Write byte data to buffer
      Uint8List watermarkedImageBytes = byteData!.buffer.asUint8List();
      // Save the watermarked image to a new file with a timestamp
      DateTime now = DateTime.now();
      String timestamp = now.toIso8601String();
      File watermarkedFile = File('${imageFile.path}_$timestamp.jpg');
      await watermarkedFile.writeAsBytes(watermarkedImageBytes);
      return watermarkedFile;
    } catch (e) {
      print('Error adding watermark: $e');
      rethrow; // Propagate the error
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> dynamicFields = [];

    if (_selectedCategory == '1' ||
        _selectedCategory == '9' ||
        _selectedCategory == '14' ||
        _selectedCategory == '30' ||
        _selectedCategory == '54') {
      dynamicFields.add(
        _buildOutlinedDropdownButton(
          value: _selectedCondition,
          labelText: 'Condition*',
          items: ['Brand New', 'Foreign Used', 'Nigerian Used']
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCondition = newValue;
              });
            }
          },
        ),
      );
    }

    if (_selectedCategory == '1' ||
        _selectedCategory == '9' ||
        _selectedCategory == '14') {
      List<Widget> additionalFields = [];

      List<String> brands = [];
      if (_selectedCategory == '1') {
        brands = [
          'Toyota',
          'Honda',
          'Tesla',
          'Mercedes-Benz',
          'BMW',
          'Ford',
          'Kia',
          'Hyundai',
          'Nissan',
          'Volkswagen',
          'Audi',
          'Chevrolet',
          'Lexus',
          'Mitsubishi',
          'Peugeot',
          'Renault',
          'Subaru'
        ];
      } else if (_selectedCategory == '9') {
        brands = [
          'Samsung',
          'Apple',
          'Tecno',
          'Huawei',
          'Xiaomi',
          'Nokia',
          'LG',
          'Sony',
          'Google',
          'OnePlus',
          'Motorola',
          'OPPO',
          'Infinix',
          'Vivo',
          'BlackBerry',
          'Lenovo',
          'ASUS'
        ];
      } else if (_selectedCategory == '14') {
        brands = [
          'LG',
          'Sony',
          'Sharp',
          'Samsung',
          'Panasonic',
          'Philips',
          'Toshiba',
          'Bose',
          'Dell',
          'HP',
          'Acer',
          'Apple',
          'Microsoft',
          'Lenovo',
          'ASUS',
          'Canon',
          'Nikon',
          'GoPro',
          'JBL',
          'Western Digital',
          'Seagate',
          'Corsair',
          'SanDisk',
          'Logitech'
        ];
      }

      additionalFields.add(
        _buildOutlinedDropdownButton(
          value: _selectedBrand.isEmpty && brands.isNotEmpty ? brands[0] : _selectedBrand,
          labelText: 'Brand',
          items: brands
              .map(
                (brand) => DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedBrand = newValue;
              });
            }
          },
        ),
      );

      additionalFields.add(
        _buildOutlinedTextField(
          controller: _modelController,
          labelText: 'Model',
        ),
      );

      dynamicFields.addAll(additionalFields);
    }

    return Scaffold(
      appBar: AppBar(
        //title: Text('Post New Ad'),
        title: const Text('Post New Ad', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                      _selectedSubCategory = ''; // Reset to empty
                      // Reset dynamic fields when category changes
                      _selectedCondition = 'Brand New';
                      _selectedBrand = '';
                      _modelController.clear();
                      loadSubCategories(int.parse(newValue));
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Select Category'),
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSubCategory.isEmpty ? null : _selectedSubCategory,
                items:
                    _subCategories.map<DropdownMenuItem<String>>((subcategory) {
                  return DropdownMenuItem<String>(
                    value: subcategory['id'].toString(),
                    child: Text(subcategory['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedSubCategory = newValue;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Select Sub Category'),
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                // Title input field
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory11.isEmpty ? null : _selectedCategory11,
                items: _categories11.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['code'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory11 = newValue;
                      _selectedSubCategory11 = 'SubCity';
                      _selectedCity = ''; // Reset city when state changes
                      //loadSubCategories11(int.parse(newValue));
                      loadSubCities(newValue);
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Select State'),
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: (_selectedCity.isNotEmpty && _subCategories11.any((item) => item['id'].toString() == _selectedCity)) 
                    ? _selectedCity 
                    : null,
                items: _subCategories11
                    .map<DropdownMenuItem<String>>((subcategory) {
                  return DropdownMenuItem<String>(
                    value: subcategory['id'].toString(),
                    child: Text(subcategory['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Select City'),
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              TextFormField(
                // Description input field
                controller: _descriptionController,
                maxLines: null, // Allows for multiple lines
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint:
                      true, // Aligns label with the multiline input
                  border: OutlineInputBorder(), // Optional, adds a border
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // Place the dynamicFields here after the first three existing form fields
              ...dynamicFields,
              const SizedBox(height: 10),
              TextFormField(
                // Price input field
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                // Tags input field
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags'),
                // Validation or other configurations for tags input
              ),
               // Image preview
              _buildImagePreview(),
              const SizedBox(height: 30),
              
              // SELECT IMAGE BUTTON - Modern Card-like Style
              GestureDetector(
                onTap: addImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Select Images',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // SUBMIT / NEXT BUTTON - Modern Card-like Style
              GestureDetector(
                onTap: () {
                  if (_isReadyToSubmit()) {
                    if (_formKey.currentState?.validate() ?? false) {
                      submitListing();
                    }
                  } else {
                    _handleNext();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _isReadyToSubmit() ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isReadyToSubmit() ? Colors.green : Colors.blue).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isReadyToSubmit() ? 'SUBMIT LISTING' : 'CONTINUE TO NEXT STEP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // SAVE & POST LATER BUTTON - Subtler Modern Style
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    submitSavedListing();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.purple.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading2
                        ? CircularProgressIndicator(color: Colors.purple.shade300)
                        : Text(
                            'Save & Post Later',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}

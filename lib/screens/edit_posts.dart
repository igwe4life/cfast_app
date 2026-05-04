import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:paystack_for_flutter/paystack_for_flutter.dart';
import '../models/package_model.dart';
import 'package_selection_screen.dart';
import 'main_screen.dart';
import 'package:flutter/services.dart';

// Helper class to store payment details
class PaymentInfo {
  final String reference;
  final double amount;
  PaymentInfo(this.reference, this.amount);
}

class EditPostScreen extends StatefulWidget {
  final dynamic item;

  const EditPostScreen(this.item, {super.key});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late String name;
  late String email;
  late String photoUrl;
  late String phone;
  late String token;

  // Define controllers for editing post details
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _selectedImage;
  final List<File> _selectedImages = [];
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  Package? _savedSelectedPackage;
  Map<int, PaymentInfo> _paidPackages = {};
  bool _isLoading = false;
  String _loadingMessage = '';
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _categories = [];
  List<dynamic> _subCategories = [];
  List<dynamic> _categories11 = []; // States
  List<dynamic> _subCategories11 = []; // Cities
  
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  String _selectedCategory11 = ''; // State code
  String _selectedCity = '';
  
  String _categoryName = 'Loading...';
  String _subCategoryName = 'Loading...';
  String _stateName = 'Loading...';
  String _cityName = 'Loading...';

  List<String> _existingImageUrls = [];
  bool _isLoadingImages = false;
  
  Set<String> uploadedFiles = {};

  @override
  void initState() {
    super.initState();
    loadAuthToken();

    // Initialize controller values with post data
    _titleController.text = (widget.item['title'] ?? '').toString();
    _descriptionController.text = (widget.item['description'] ?? '').toString();
    _tagsController.text = (widget.item['tags'] ?? '').toString();
    _priceController.text = (widget.item['price'] ?? '').toString();
    _phoneController.text = (widget.item['phone'] ?? '').toString();
    
    // Initialize IDs from item
    _selectedCategory = (widget.item['category_id'] ?? '').toString();
    _selectedSubCategory = (widget.item['sub_category_id'] ?? '').toString();
    _selectedCategory11 = (widget.item['state_code'] ?? '').toString();
    _selectedCity = (widget.item['city_id'] ?? '').toString();
    
    // Initial display names from widget.item as fallback
    _categoryName = (widget.item['category_name'] ?? widget.item['category'] ?? 'Category').toString();
    _subCategoryName = (widget.item['sub_category_name'] ?? widget.item['sub_category'] ?? 'Sub-Category').toString();
    _stateName = (widget.item['state_name'] ?? widget.item['state'] ?? 'State').toString();
    _cityName = (widget.item['city_name'] ?? widget.item['city'] ?? 'City').toString();

    // Initialize IAP Stream
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
       print('IAP Stream Error: $error');
    });

    loadCategories();
    loadStates();
    if (_selectedCategory.isNotEmpty) {
      loadSubCategories(int.parse(_selectedCategory));
    }
    if (_selectedCategory11.isNotEmpty) {
      loadSubCities(_selectedCategory11);
    }
    
    // Fetch existing images
    fetchExistingImages();
  }

  Future<void> fetchExistingImages() async {
    // We need a URL to fetch images from. widget.item['id'] or widget.item['itemUrl']?
    // Based on product_screen.dart, it needs 'purl'.
    // If widget.item has 'itemUrl', use it. Otherwise, we might need another way.
    String? purl = widget.item['itemUrl']?.toString();
    if (purl == null || purl.isEmpty) return;

    setState(() => _isLoadingImages = true);
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/cfastapi/get_images.php?purl=$purl'),
      );
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        setState(() {
          _existingImageUrls = List<String>.from(jsonData);
        });
      }
    } catch (e) {
      print('Error fetching existing images: $e');
    } finally {
      setState(() => _isLoadingImages = false);
    }
  }

  Future<void> loadCategories() async {
    try {
      String jsonString = await rootBundle.loadString('assets/categories.json');
      setState(() {
        _categories = json.decode(jsonString)['strippedData'];
        var cat = _categories.firstWhere(
          (c) => c['id'].toString() == _selectedCategory, 
          orElse: () => null
        );
        if (cat != null) _categoryName = cat['name'];
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> loadSubCategories(int categoryId) async {
    if (categoryId <= 0) return;
    try {
      final res = await http.get(Uri.parse("$baseUrl/cfastapi/get_subcategories.php?id=$categoryId"));
      setState(() {
        _subCategories = jsonDecode(res.body);
        var sub = _subCategories.firstWhere(
          (s) => s['id'].toString() == _selectedSubCategory, 
          orElse: () => null
        );
        if (sub != null) _subCategoryName = sub['name'];
      });
    } catch (e) {
      print('Error loading sub-categories: $e');
    }
  }

  Future<void> loadStates() async {
    try {
      String jsonString = await rootBundle.loadString('assets/states.json');
      setState(() {
        _categories11 = json.decode(jsonString)['strippedData'];
        var st = _categories11.firstWhere(
          (s) => s['code'].toString() == _selectedCategory11, 
          orElse: () => null
        );
        if (st != null) _stateName = st['name'];
      });
    } catch (e) {
      print('Error loading states: $e');
    }
  }

  Future<void> loadSubCities(String stateCode) async {
    if (stateCode.isEmpty || stateCode == '0') return;
    try {
      final res = await http.get(Uri.parse("$baseUrl/cfastapi/get_cities.php?parentId=$stateCode"));
      setState(() {
        _subCategories11 = jsonDecode(res.body);
        var ct = _subCategories11.firstWhere(
          (c) => c['id'].toString() == _selectedCity, 
          orElse: () => null
        );
        if (ct != null) _cityName = ct['name'];
      });
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
           String productId = purchaseDetails.productID;
           print('IAP Success: $productId');
           if (_savedSelectedPackage != null) {
                setState(() {
                    double paidAmount = (double.parse(_savedSelectedPackage!.price) * 100).toDouble() / 100;
                    String ref = purchaseDetails.purchaseID ?? 'IAP_REF';
                    _paidPackages[_savedSelectedPackage!.id] = PaymentInfo(ref, paidAmount);
                });
           }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        FocusScope.of(context).unfocus();
    });
  }

  Future<void> _buyProduct(Package package) async {
    String productId = Platform.isIOS ? package.appleProductId : 'package_${package.id}';
    bool available = await _inAppPurchase.isAvailable();
    if (!available) return;
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return;
    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  Future<void> loadAuthToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
      
      // If widget item didn't have phone, try using profile phone
      if (_phoneController.text.isEmpty) {
         _phoneController.text = phone;
      }
    });
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_existingImageUrls.isNotEmpty) ...[
          const Text('Existing Images', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _existingImageUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedImages.isNotEmpty) ...[
          const Text('New Images', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                File image = _selectedImages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Ad Listing', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // READ-ONLY CATEGORY & LOCATION DISPLAY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildReadOnlyItem('Category', _categoryName),
                        const Divider(),
                        _buildReadOnlyItem('Sub-Category', _subCategoryName),
                        const Divider(),
                        _buildReadOnlyItem('State', _stateName),
                        const Divider(),
                        _buildReadOnlyItem('City', _cityName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(labelText: 'Tags', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a price' : null,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Required)',
                      //prefixText: '+234 ',
                      prefixText: '',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty) ? 'Please enter a phone number' : null,
                  ),
                  const SizedBox(height: 24.0),
                  
                  // SELECT IMAGE BUTTON ABOVE PREVIEW
                  GestureDetector(
                    onTap: addImages,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12.0),
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
                  
                  // Image preview
                  _buildImagePreview(),
                  const SizedBox(height: 30),
                  
                  // SUBMIT BUTTON - Modern Card-like Style
                  GestureDetector(
                    onTap: () {
                      if (_isReadyToSubmit()) {
                        if (_formKey.currentState?.validate() ?? false) {
                          _submitEditedPost();
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
                                _isReadyToSubmit() ? 'SUBMIT LISTING' : 'NEXT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isReadyToSubmit() {
    // If no package is selected yet, not ready
    if (_savedSelectedPackage == null) return false;
    
    // If it's a free package, ready
    if (_savedSelectedPackage!.price == '0.00' || _savedSelectedPackage!.price == '0') return true;
    
    // If it's a paid package, check if payment info exists
    return _paidPackages.containsKey(_savedSelectedPackage!.id);
  }

  void _handleNext() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    showDialog(
       context: context,
       builder: (dialogContext) => PackageSelectionScreen(
         token: token,
         onPackageSelected: (package) {
           Navigator.of(dialogContext).pop();
           if (package.price == '0.00' || package.price == '0') {
               setState(() => _savedSelectedPackage = package);
           } else {
               setState(() => _savedSelectedPackage = package);
               _handlePayment(package);
           }
         },
       ),
    );
  }

  Widget _buildReadOnlyItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayment(Package package) {
    if (Platform.isIOS) {
        _buyProduct(package);
    } else {
        _payWithPaystack(package, PAYSTACK_SECRET_KEY);
    }
  }

  void _payWithPaystack(Package package, String secretKey) async {
    PaystackFlutter paystackFlutter = PaystackFlutter();
    paystackFlutter.pay(
      context: context, 
      secretKey: secretKey, 
      callbackUrl: 'https://standard.paystack.co/close', 
      email: email,
      amount: (double.parse(package.price) * 100).toDouble(),
      onCancelled: (paystackCallback) {
        Fluttertoast.showToast(msg: 'Payment cancelled');
      },
      onSuccess: (paystackCallback) {
        setState(() {
          double paidAmount = (double.parse(package.price) * 100).toDouble() / 100;
          _paidPackages[package.id] = PaymentInfo(paystackCallback.reference, paidAmount);
        });
      },
    );
  }

  void _submitEditedPost() async {
    setState(() => _isLoading = true);
    
    // Format phone number
    String finalPhone = _phoneController.text.trim();
    // Prepend +234 only if it doesn't start with it already and user expects it, 
    // but the request was specifically "remove the prepended +234".
    // So we just send what's in the controller.

    // Prepare data to post
    var data = {
      'category_id': _selectedSubCategory.isNotEmpty ? _selectedSubCategory : _selectedCategory,
      'package_id': _savedSelectedPackage?.id.toString() ?? '1',
      'country_code': 'NG',
      'email': email,
      'phone': finalPhone, 
      'phone_country': 'NG',
      'city_id': _selectedCity,
      'auth_field': 'email',
      'contact_name': name,
      'admin_code': '0',
      'accept_terms': 'true',
      'title': _titleController.text,
      'description': _descriptionController.text,
      'tags': _tagsController.text,
      'price': _priceController.text,
    };

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/posts'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Language': 'en',
      'X-AppType': 'docs',
      'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
    });

    // Add image file
    for (File? image in _selectedImages) {
      if (image != null) {
        var imageField =
            await http.MultipartFile.fromPath('pictures[]', image.path);
        request.files.add(imageField);
      }
    }

    // Add form fields
    request.fields.addAll(data);

    // Send multipart request
    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseBody);
      final updateUrl = Uri.parse(
          '$baseUrl/cfastapi/update_saved.php?id=${widget.item['id']}');

      ///Fluttertoast.showToast(msg: responseBody.toString());
      if (response.statusCode == 200 || response.statusCode == 201) { // 201 Created is often used too
        // Handle successful response
        print('Post updated successfully');

        ///Fluttertoast.showToast(msg: decodedResponse['message']);
        final responses = await http.get(updateUrl);
        
        // Navigation should be here regardless of update_saved status
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (context) => const MainScreen()),
           (route) => false,
         );
      } else {
        print('Failed to update post: ${response.statusCode}');
        Fluttertoast.showToast(msg: 'Update failed: ${decodedResponse['message'] ?? responseBody}');
      }
    } catch (e) {
      print('Exception while updating post: $e');
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
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


  Future<void> addImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Future.wait(images.map((image) async {
        File file = File(image.path);
        bool isScreenshot = await isImageScreenshot(file);
        if (isScreenshot) return;
        if (uploadedFiles.contains(image.path)) return;

        final decodedImage = await decodeImageFromList(await file.readAsBytes());
        if (decodedImage.width > 400) {
          File watermarkedImage = await _addWatermarkToImages(file);
          setState(() {
            _selectedImages.add(watermarkedImage);
          });
          uploadedFiles.add(image.path);
        }
      }));
    } finally {
      Navigator.pop(context);
      FocusScope.of(context).unfocus();
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
}

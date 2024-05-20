import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:image_watermark/image_watermark.dart';
import 'package:shop_cfast/screens/saved_listing.dart';
import '../constants.dart';
import 'login_page.dart';

class AddListingScreen extends StatefulWidget {
  @override
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _categories11 = [];
  List<dynamic> _lgas = [];

  List<dynamic> _subCategories = [];
  List<dynamic> _subCategories11 = [];

  List<dynamic> _myState = [];
  List<dynamic> _myCities = [];

  List data = [];
  int _value = 1;

  List<Map<String, dynamic>> _cities = [];

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

  String _selectedCategory = 'Category';
  String _selectedCategory11 = 'Category11';
  String _selectedSubCategory = 'SubCategory';
  String _selectedSubCategory11 = 'City';
  String _selectedState = 'State';
  String _selectedSubCity = 'City';
  String _selectedCity = ''; // Define _selectedCity variable

  File? _selectedImage;
  List<File?> _selectedImages = List.generate(5, (index) => null);

  late SharedPreferences sharedPreferences;

  Future<void> checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
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
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadAuthToken();
    loadCategories();
    loadStates();
    loadCities();
    //getData();
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

  Future<void> loadCities() async {
    try {
      setState(() {
        _isLoadingCities = true; // Set loading state
      });

      bool fetchNextPage = true;

      while (fetchNextPage) {
        var response = await http.get(
          Uri.parse('$baseUrl/api/countries/NG/cities?page=$_currentPage'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Content-Language': 'en',
            'X-AppType': 'docs',
            'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw='
          },
        );

        if (response.statusCode == 200) {
          var citiesData = json.decode(response.body)['result']['data'];
          if (citiesData.isNotEmpty) {
            setState(() {
              _cities.addAll(List<Map<String, dynamic>>.from(citiesData));
              _currentPage++; // Move to next page
            });
          } else {
            fetchNextPage = false; // Stop if no more data available
          }
        } else {
          print('Failed to load cities');
          fetchNextPage = false; // Stop on failure
        }
      }
    } catch (e) {
      print('Exception while loading cities: $e');
    } finally {
      setState(() {
        _isLoadingCities = false; // Set loading state to false after completion
      });
    }
  }

  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
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
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        for (File? image in _selectedImages)
          if (image != null)
            GestureDetector(
              onTap: () {
                // Show a dialog to confirm deletion
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Delete Image'),
                      content:
                          Text('Are you sure you want to delete this image?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Remove the selected image from the list
                            setState(() {
                              _selectedImages.remove(image);
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(image),
                  Icon(
                    Icons.delete,
                    size: 36, // Set the size of the icon
                    color: Colors.red, // Set the color of the icon
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> saveListing() async {
    // Show loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
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
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to saved_listing.dart after a delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ViewSavedPosts()),
        );
      });
    } catch (error) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while saving the listing'),
          duration: Duration(seconds: 2),
        ),
      );

      print('Error saving listing: $error');
    }
  }

  void submitSavedListing() async {
    setState(() {
      _isLoading2 = true; // Set loading state
    });

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
      'category_id': selectedSubCategoryId,
      'package_id': '1',
      'country_code': 'NG',
      'email': email,
      'phone': phone,
      'user_id': uid.toString(),
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
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(responseBody);

        if (decodedResponse['success'] == true) {
          // Success toast and navigation to home screen
          Fluttertoast.showToast(msg: decodedResponse['message']);
          Navigator.of(context).pop(); // Navigate back to home screen
        } else {
          // Failure toast
          Fluttertoast.showToast(
              msg:
                  'Listing save and post later failed: ${decodedResponse['message']}');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        // Failure toast with status code
        // if (response.statusCode == 422) {
        //   print(await response.stream.bytesToString());
        //   Fluttertoast.showToast(msg: decodedResponse['message']);
        //   // Failure toast with status code
        //   Fluttertoast.showToast(
        //       msg:
        //           'Listing creation failed with status code: ${response.statusCode}');
        // }
        if (response.statusCode == 422) {
          final errorResponse = await response.stream.bytesToString();
          Fluttertoast.showToast(
              msg: 'Listing save and post later failed: $errorResponse');
        }
        // Fluttertoast.showToast(
        //     msg:
        //         'Listing creation failed with status code: ${response.statusCode}');
        // Print response body for debugging
        print(await response.stream.bytesToString());
      }
    } catch (e) {
      print('Exception: $e');
      // Failure toast
      Fluttertoast.showToast(msg: 'Listing save and post later failed: $e');
    } finally {
      setState(() {
        _isLoading2 = false; // Set loading state to false after submission
      });
    }
  }

  void submitListing() async {
    setState(() {
      _isLoading = true; // Set loading state
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
      'package_id': '1',
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
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = json.decode(responseBody);

        if (decodedResponse['success'] == true) {
          // Success toast and navigation to home screen
          Fluttertoast.showToast(msg: decodedResponse['message']);
          Navigator.of(context).pop(); // Navigate back to home screen
        } else {
          // Failure toast
          Fluttertoast.showToast(
              msg: 'Listing creation failed: ${decodedResponse['message']}');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        // Failure toast with status code
        // if (response.statusCode == 422) {
        //   print(await response.stream.bytesToString());
        //   Fluttertoast.showToast(msg: decodedResponse['message']);
        //   // Failure toast with status code
        //   Fluttertoast.showToast(
        //       msg:
        //           'Listing creation failed with status code: ${response.statusCode}');
        // }
        if (response.statusCode == 422) {
          final errorResponse = await response.stream.bytesToString();
          Fluttertoast.showToast(
              msg: 'Listing creation failed: $errorResponse');
        }
        // Fluttertoast.showToast(
        //     msg:
        //         'Listing creation failed with status code: ${response.statusCode}');
        // Print response body for debugging
        print(await response.stream.bytesToString());
      }
    } catch (e) {
      print('Exception: $e');
      // Failure toast
      Fluttertoast.showToast(msg: 'Listing creation failed: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false after submission
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

  Set<String> uploadedFiles = Set(); // Maintain a set of uploaded file paths

  Future<void> addImages() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      for (XFile image in images) {
        // Get image file
        File file = File(image.path);

        // Check if image is a screenshot
        bool isScreenshot = await isImageScreenshot(file);

        // If the image is not a screenshot
        if (!isScreenshot) {
          // Check if the file has already been uploaded
          if (!uploadedFiles.contains(image.path)) {
            // Get image dimensions
            final decodedImage =
                await decodeImageFromList(await file.readAsBytes());
            int width = decodedImage.width;

            // Check if image width is greater than 600 pixels
            if (width > 400) {
              // Watermark the image before adding it to the list
              File watermarkedImage = await _addWatermarkToImages(file);
              setState(() {
                _selectedImages.add(watermarkedImage);
              });
              // Add the file path of watermarked image to the uploaded files set
              uploadedFiles.add(watermarkedImage.path);
            } else {
              // Remove the image from the list
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Image Width Alert'),
                    content: Text(
                        'Image with width less than or equal to 400 pixels is not allowed.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            // Alert user that the file has already been uploaded
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('File Upload Alert'),
                  content: Text('This file has already been uploaded.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          // Alert user that screenshot images are not allowed
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Screenshot Alert'),
                content: Text('Screenshot images are not allowed.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
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
      String watermarkText = '${name}\n Posted on Cfast.NG';
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
      throw e; // Propagate the error
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
          value: 'New',
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
              // Handle changes in the dropdown value here
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
          value: brands.isNotEmpty ? brands[0] : '',
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
              // Handle changes in the brand dropdown value here
            }
          },
        ),
      );

      additionalFields.add(
        _buildOutlinedTextField(
          controller: TextEditingController(),
          labelText: 'Model',
        ),
      );

      dynamicFields.addAll(additionalFields);
    }

    return Scaffold(
      appBar: AppBar(
        //title: Text('Post New Ad'),
        title: Text('Post New Ad', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: _selectedCategory,
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
                      _selectedSubCategory = 'SubCategory';
                      loadSubCategories(int.parse(newValue));
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Select Category'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
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
                decoration: InputDecoration(labelText: 'Select Sub Category'),
              ),
              SizedBox(height: 10),
              TextFormField(
                // Title input field
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory11,
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
                      //loadSubCategories11(int.parse(newValue));
                      loadSubCities(newValue);
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Select State'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCity,
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
                decoration: InputDecoration(labelText: 'Select City'),
              ),
              SizedBox(height: 10),
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
              SizedBox(height: 10),
              // Place the dynamicFields here after the first three existing form fields
              ...dynamicFields,
              SizedBox(height: 10),
              TextFormField(
                // Price input field
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                // Tags input field
                controller: _tagsController,
                decoration: InputDecoration(labelText: 'Tags'),
                // Validation or other configurations for tags input
              ),
              // Image preview
              _buildImagePreview(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addImages,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange, // Text color
                ),
                child: Text(
                  'Select Image',
                  style: TextStyle(color: Colors.white), // Text color
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    submitListing();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Text color
                ),
                child: _isLoading
                    ? CircularProgressIndicator() // Loading indicator
                    : Text(
                        'Submit',
                        style: TextStyle(color: Colors.white), // Text color
                      ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    submitSavedListing();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.purple, // Text color
                ),
                child: _isLoading2
                    ? CircularProgressIndicator() // Loading indicator
                    : Text(
                        'Save & Post Later',
                        style: TextStyle(color: Colors.white), // Text color
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

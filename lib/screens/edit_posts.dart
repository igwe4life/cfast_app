import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPostScreen extends StatefulWidget {
  final dynamic item;

  EditPostScreen(this.item);

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
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _tagsController = TextEditingController();
  TextEditingController _priceController = TextEditingController();

  File? _selectedImage;
  List<File?> _selectedImages = List.generate(5, (index) => null);

  @override
  void initState() {
    super.initState();
    loadAuthToken();

    // Initialize controller values with post data
    _titleController.text = widget.item['title'] ?? '';
    _descriptionController.text = widget.item['description'] ?? '';
    _tagsController.text = widget.item['tags'] ?? '';
    _priceController.text = widget.item['price'] ?? '';
    // _categoryController.text = widget.post['category_id'];
    // _cityController.text = widget.post['city_id'];
  }

  Future<void> loadAuthToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      name = sharedPreferences.getString("name") ?? "Name";
      email = sharedPreferences.getString("email") ?? "Email";
      photoUrl = sharedPreferences.getString("photo_url") ?? "";
      phone = sharedPreferences.getString("phone") ?? "Phone";
      token = sharedPreferences.getString("token") ?? "token";
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Ad Listing', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(labelText: 'Tags'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              // Image preview
              _buildImagePreview(),
              SizedBox(height: 16.0),
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
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _submitEditedPost();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Text color
                ),
                child: Text('Submit Ad Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitEditedPost() async {
    // Show CircularProgressIndicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    // Prepare data to post
    var data = {
      'category_id': widget.item['category_id'].toString(),
      'package_id': '1',
      'country_code': 'NG',
      'email': email,
      'phone': phone,
      'phone_country': 'NG',
      'city_id': widget.item['city_id'].toString(),
      'auth_field': 'email',
      'contact_name': name,
      'admin_code': '0',
      'accept_terms': 'true', // boolean value represented as string
      'title': _titleController.text,
      'description': _descriptionController.text,
      'tags': _tagsController.text,
      'price': _priceController.text, // New field for price
    };

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://cfast.ng/api/posts'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
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
          'https://cfast.ng/cfastapi/update_saved.php?id=${widget.item['id']}');

      ///Fluttertoast.showToast(msg: responseBody.toString());
      if (response.statusCode == 200) {
        // Handle successful response
        print('Post updated successfully');

        ///Fluttertoast.showToast(msg: decodedResponse['message']);
        final responses = await http.get(updateUrl);

        // Check if the request was successful
        if (responses.statusCode == 200) {
          // Request was successful, handle the response if needed
          print('Update request successful');
          Fluttertoast.showToast(msg: 'Update request successful');
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Request failed
          print('Failed to make update request: ${responses.statusCode}');
          Fluttertoast.showToast(msg: 'Update request successful');
        }
        // Success toast and navigation to home screen
        //Fluttertoast.showToast(msg: decodedResponse['message']);
        ///Navigator.of(context).pop(); // Navigate back to home screen
        // You can navigate back to previous screen or show a success message
      } else {
        // Handle error response
        print('Failed to update post: ${decodedResponse.statusCode}');
        Fluttertoast.showToast(
            msg:
                'Listing creation update failed: ${decodedResponse['message']}');
        // Hide CircularProgressIndicator
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      // Handle exceptions
      print('Exception while updating post: $e');
      Fluttertoast.showToast(msg: 'Listing creation failed: $e');
      // Hide CircularProgressIndicator
      Navigator.pop(context); // Close the dialog
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
            if (width > 600) {
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
                        'Image with width less than or equal to 600 pixels is not allowed.'),
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
}

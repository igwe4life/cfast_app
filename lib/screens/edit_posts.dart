import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

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
  final List<File?> _selectedImages = List.generate(5, (index) => null);

  @override
  void initState() {
    super.initState();
    loadAuthToken();

    // Initialize controller values with post data
    _titleController.text = (widget.item['title'] ?? '').toString();
    _descriptionController.text = (widget.item['description'] ?? '').toString();
    _tagsController.text = (widget.item['tags'] ?? '').toString();
    _priceController.text = (widget.item['price'] ?? '').toString();
    // Initialize phone, stripping country code if present for display, or just showing generic
    // For now, assuming we just show what's there or user's phone, but user wants to add country code "in front" (UI prefix)
    // So we should put the number WITHOUT the prefix in the controller if we use prefixText.
    // However, simplicity: let's load the raw phone number.
     _phoneController.text = (widget.item['phone'] ?? '').toString();
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
                      title: const Text('Delete Image'),
                      content:
                          const Text('Are you sure you want to delete this image?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Remove the selected image from the list
                            setState(() {
                              _selectedImages.remove(image);
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
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                   Image.file(image),
                  const Icon(
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
        title: const Text('Edit Ad Listing', style: TextStyle(color: Colors.white)),
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
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags'),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Required)',
                  prefixText: '+234 ',
                ),
                keyboardType: TextInputType.phone,
              ),
              // Image preview
              _buildImagePreview(),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: addImages,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange, // Text color
                ),
                child: const Text(
                  'Select Image',
                  style: TextStyle(color: Colors.white), // Text color
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _submitEditedPost();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Text color
                ),
                child: const Text('Submit Ad Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitEditedPost() async {
    if (_phoneController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Phone number is required');
      return;
    }

    // Show CircularProgressIndicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    
    // Format phone number with country code if not present
    String finalPhone = _phoneController.text.trim();
    // Assuming the user types the local number, we prepend +234/country code if we want to force it.
    // The requirement says "add country code in front". 
    // If we use prefixText in decoration, it's visual. We might want to prepend it to data.
    // However, let's just send what's in the controller combined with our knowledge, or just the controller if the API expects local.
    // Let's assume we prepend +234 if it's missing.
    // Actually, usually APIs want the full E.164.
    // Let's stick to sending what the user typed but ensuring it's not empty. 
    // Wait, "add country code in front" usually implies visual prefix. logic-wise, let's prepend it for data.
    if (!finalPhone.startsWith('+')) {
         finalPhone = '+234$finalPhone';
    }

    // Prepare data to post
    var data = {
      'category_id': widget.item['category_id'].toString(),
      'package_id': '1',
      'country_code': 'NG',
      'email': email,
      'phone': finalPhone, 
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
      Uri.parse('$baseUrl/api/posts'),
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
          '$baseUrl/cfastapi/update_saved.php?id=${widget.item['id']}');

      ///Fluttertoast.showToast(msg: responseBody.toString());
      if (response.statusCode == 200 || response.statusCode == 201) { // 201 Created is often used too
        // Handle successful response
        print('Post updated successfully');

        ///Fluttertoast.showToast(msg: decodedResponse['message']);
        final responses = await http.get(updateUrl);
        
        // Navigation should be here regardless of update_saved status
         Navigator.of(context).popUntil((route) => route.isFirst);

        // Check if the request was successful
        if (responses.statusCode == 200) {
          // Request was successful, handle the response if needed
          print('Update request successful');
          Fluttertoast.showToast(msg: 'Update request successful');
        } else {
          // Request failed
          print('Failed to make update request: ${responses.statusCode}');
          Fluttertoast.showToast(msg: 'Saved status update failed: ${responses.statusCode}');
        }
        // Success toast and navigation to home screen
        //Fluttertoast.showToast(msg: decodedResponse['message']);
        ///Navigator.of(context).pop(); // Navigate back to home screen
        // You can navigate back to previous screen or show a success message
      } else {
        // Handle error response
        print('Failed to update post: ${response.statusCode}');
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

  Set<String> uploadedFiles = {}; // Maintain a set of uploaded file paths

  Future<void> addImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

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
                  title: const Text('Image Width Alert'),
                  content: const Text(
                      'Image with width less than or equal to 600 pixels is not allowed.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
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
                title: const Text('File Upload Alert'),
                content: const Text('This file has already been uploaded.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
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
              title: const Text('Screenshot Alert'),
              content: const Text('Screenshot images are not allowed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
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

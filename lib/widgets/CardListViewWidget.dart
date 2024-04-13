import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CardListViewWidget extends StatefulWidget {
  @override
  _CardListViewWidgetState createState() => _CardListViewWidgetState();
}

class _CardListViewWidgetState extends State<CardListViewWidget> {
  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    fetchDataFromAPI();
  }

  Future<void> fetchDataFromAPI() async {
    final response =
        await http.get('https://bworldapp.online/cfastapi/test.php' as Uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        data = jsonData.cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Failed to load data from the API.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          elevation: 3,
          margin: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-width image
              Image.network(
                item['image'],
                width: double.infinity,
                height: 200, // Set the desired height
                fit: BoxFit.cover,
              ),
              // Price
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Price: ${item['price']}'),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Title: ${item['title']}',
                    style: TextStyle(fontSize: 10)),
              ),
              // Location
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Location: ${item['location']}'),
              ),
              // Add more details as needed
              // ...
              // onTap: () {
              //   // Handle item click here, e.g., open a new screen with item details.
              //   // You can use item['itemUrl'] to navigate to the item's URL.
              // },
            ],
          ),
        );
      },
    );
  }
}

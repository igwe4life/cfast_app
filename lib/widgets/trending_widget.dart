import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class StaggeredGridViewWidget extends StatefulWidget {
  @override
  _StaggeredGridViewWidgetState createState() =>
      _StaggeredGridViewWidgetState();
}

class _StaggeredGridViewWidgetState extends State<StaggeredGridViewWidget> {
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse("https://bworldapp.online/cfastapi/test.php"));

    if (response.statusCode == 200) {
      setState(() {
        _data = json.decode(response.body).cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _data.isEmpty
        ? Center(child: CircularProgressIndicator())
        : StaggeredGridView.countBuilder(
            crossAxisCount: 2,
            itemCount: _data.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildListItem(index),
            staggeredTileBuilder: (int index) => StaggeredTile.fit(1),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
          );
  }

  Widget _buildListItem(int index) {
    final item = _data[index];
    return Card(
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            item['image'],
            fit: BoxFit.cover,
            height: 150,
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'],
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4.0),
                Text(item['price']),
                SizedBox(height: 4.0),
                Text('Location: ${item['location']}'),
                SizedBox(height: 4.0),
                Text('Date: ${item['date']} at ${item['time']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

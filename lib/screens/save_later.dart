import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'edit_posts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ApiListViewScreen extends StatefulWidget {
  @override
  _ApiListViewScreenState createState() => _ApiListViewScreenState();
}

class _ApiListViewScreenState extends State<ApiListViewScreen> {
  late Future<List<dynamic>> _futureData;
  int uid = 0;

  @override
  void initState() {
    super.initState();
    _futureData = _loadAndFetchData();
  }

  Future<List<dynamic>> _loadAndFetchData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    uid = sharedPreferences.getInt("uid") ?? 0;

    if (uid == 0) {
      return [];
    }

    final url =
        Uri.parse('$baseUrl/cfastapi/fetch_saved_posts.php?user_id=$uid');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      try {
        var decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data') && decoded['data'] is List) {
          return decoded['data'];
        } else {
          return [];
        }
      } catch (e) {
        return [];
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Saved Posts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Something went wrong', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No saved posts yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                
                DateTime date;
                String createdAtStr = item['created_at']?.toString() ?? '';
                try {
                  date = createdAtStr.isNotEmpty ? DateTime.parse(createdAtStr) : DateTime.now();
                } catch (e) {
                  date = DateTime.now();
                }
                String formattedDate =
                DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPostScreen(item),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Icon(Icons.chevron_right,
                                color: Colors.grey[400], size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
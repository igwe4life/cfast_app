import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl package for date formatting
import '../constants.dart';

class GetFeedbackScreen extends StatefulWidget {
  final String storeName;

  const GetFeedbackScreen({super.key, required this.storeName});

  @override
  _GetFeedbackScreenState createState() => _GetFeedbackScreenState();
}

class _GetFeedbackScreenState extends State<GetFeedbackScreen> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/cfastapi/fetch_feedback.php?stname=${widget.storeName}'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          records = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Feedback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)))
          : records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.feedback_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No feedback found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to leave feedback',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    DateTime date = DateTime.tryParse(
                            records[index]['created_at'] ?? '') ??
                        DateTime.now();
                    String formattedDate =
                        DateFormat('MMM d\'th\', yyyy hh:mm a').format(date);

                    return Container(
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getIconBg(records[index]['rating']),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: _getIcon(records[index]['rating']),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${records[index]['post_title'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${records[index]['comment'] ?? 'No comment'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 13, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getIconBg(String rating) {
    switch (rating) {
      case '3':
        return const Color(0xFFFEE2E2);
      case '1':
        return const Color(0xFFD1FAE5);
      case '2':
        return const Color(0xFFFFF3CD);
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  Icon _getIcon(String rating) {
    switch (rating) {
      case '3':
        return const Icon(Icons.thumbs_up_down, color: Color(0xFFDC2626), size: 22);
      case '1':
        return const Icon(Icons.thumb_up_alt, color: Color(0xFF059669), size: 22);
      case '2':
        return const Icon(Icons.thumb_down_alt, color: Color(0xFFD97706), size: 22);
      default:
        return const Icon(Icons.check_circle, color: Color(0xFF059669), size: 22);
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';

class FeedbackWidget extends StatefulWidget {
  final String storeName;

  const FeedbackWidget({Key? key, required this.storeName}) : super(key: key);

  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, Future<Map<String, dynamic>>> _feedbackCache =
      <String, Future<Map<String, dynamic>>>{};

  late Future<Map<String, dynamic>> _futureData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureData = _getCachedData();
  }

  @override
  void didUpdateWidget(covariant FeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeName != widget.storeName) {
      _futureData = _getCachedData();
    }
  }

  Future<Map<String, dynamic>> _getCachedData() {
    final storeName = widget.storeName.trim();
    if (storeName.isEmpty) {
      return Future<Map<String, dynamic>>.value({
        'data': <dynamic>[],
        'message': '',
      });
    }

    return _feedbackCache.putIfAbsent(storeName, () {
      return fetchData(storeName).catchError((Object error) {
        _feedbackCache.remove(storeName);
        throw error;
      });
    });
  }

  Future<Map<String, dynamic>> fetchData(String storeName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cfastapi/fetch_feedback.php').replace(
          queryParameters: {'stname': storeName},
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error: $error');
      rethrow; // Rethrow the error to propagate it further
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data!;
          final List<dynamic> feedbackData =
              (data['data'] as List<dynamic>?) ?? <dynamic>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (feedbackData.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 12),
                  child: Text(
                    'Feedback about seller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Column(
                children: feedbackData.take(2).map((feedback) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(feedback['url']),
                        ),
                        title: Text(feedback['post_title']),
                        subtitle: Text(feedback['comment']),
                        trailing: const Icon(Icons.arrow_forward, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (feedbackData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No reviews available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
            ],
          );
        }
      },
    );
  }
}

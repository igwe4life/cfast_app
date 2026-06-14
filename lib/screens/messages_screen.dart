import 'package:flutter/material.dart';
import 'package:shop_cfast/widgets/saved_list.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<MessagesScreen> {
  late SavedList _gridHome; // Create a variable to store the GridHome widget

  @override
  void initState() {
    super.initState();
    _gridHome = const SavedList(); // Initialize the GridHome widget once
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        centerTitle: true,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints.expand(height: 50),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: Color(0xFF1D4ED8),
                unselectedLabelColor: Color(0xFF9CA3AF),
                indicatorColor: Color(0xFF1D4ED8),
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(text: 'Read'),
                  Tab(text: 'Unread'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_outlined,
                              size: 40, color: Color(0xFF1D4ED8)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No read messages',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your read messages will appear here',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_unread_outlined,
                              size: 40, color: Color(0xFF1D4ED8)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No unread messages',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your unread messages will appear here',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

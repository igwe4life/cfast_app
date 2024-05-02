import 'package:flutter/material.dart';
import 'package:shop_cfast/widgets/saved_list.dart';

class MessagesScreen extends StatefulWidget {
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
        title: Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints.expand(height: 50),
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.blueAccent,
                tabs: [
                  Tab(text: 'Read'),
                  Tab(text: 'Unread'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Ads
                  // _gridHome,
                  ListView.builder(
                    itemCount:
                        1, // Replace with the actual number of API results
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text('No new messages!'),
                          // trailing: ElevatedButton(
                          //   onPressed: () {
                          //     // Implement the logic to view ads for the selected search
                          //   },
                          //   child: Text('View Ads'),
                          // ),
                        ),
                      );
                    },
                  ),
                  // Tab 2: Searches
                  SearchesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implement your API call and card display logic here
    // You can replace this with your actual implementation
    // return ListView.builder(
    //   itemCount: 5, // Replace with the actual number of API results
    //   itemBuilder: (context, index) {
    //     return Card(
    //       margin: EdgeInsets.all(8.0),
    //       child: ListTile(
    //         title: Text('Search Term $index'),
    //         trailing: ElevatedButton(
    //           onPressed: () {
    //             // Implement the logic to view ads for the selected search
    //           },
    //           child: Text('View Ads'),
    //         ),
    //       ),
    //     );
    //   },
    // );
    return ListView.builder(
      itemCount: 1, // Replace with the actual number of API results
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('No unread messages!'),
            // trailing: ElevatedButton(
            //   onPressed: () {
            //     // Implement the logic to view ads for the selected search
            //   },
            //   child: Text('View Ads'),
            // ),
          ),
        );
      },
    );
  }
}

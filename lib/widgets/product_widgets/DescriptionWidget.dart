import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Expandable Description'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExpandableDescriptionWidget(
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              ),
              // You can add more ExpandableDescriptionWidget instances or other widgets here
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandableDescriptionWidget extends StatefulWidget {
  final String description;

  ExpandableDescriptionWidget({required this.description});

  @override
  _ExpandableDescriptionWidgetState createState() =>
      _ExpandableDescriptionWidgetState();
}

class _ExpandableDescriptionWidgetState
    extends State<ExpandableDescriptionWidget> {
  bool isExpanded = false;
  late String displayedText;

  @override
  void initState() {
    super.initState();
    // Initially display the first 100 characters
    displayedText = widget.description.substring(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Description',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        SizedBox(height: 8.0),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
              if (isExpanded) {
                displayedText = widget.description; // Show full text
              } else {
                displayedText = widget.description.substring(0, 100);
              }
            });
          },
          child: RichText(
            maxLines: isExpanded ? null : 5,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: displayedText,
              style: TextStyle(
                color: Colors.black,
              ),
              children: [
                if (!isExpanded)
                  TextSpan(
                    text: '...', // Adding ellipsis for the collapsed text
                    style: TextStyle(color: Colors.blue),
                  ),
                TextSpan(
                  text: isExpanded ? ' Hide' : ' Show more',
                  // Changed 'Show less' to 'Show more'
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/login_page.dart';

class CallButtonsBar extends StatelessWidget {
  final VoidCallback onRequestCallPressed;
  final VoidCallback onMakeCallPressed;
  final VoidCallback onWhatsappPressed;

  const CallButtonsBar({
    Key? key,
    required this.onRequestCallPressed,
    required this.onMakeCallPressed,
    required this.onWhatsappPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            alignment: Alignment.center, // Center the buttons
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the buttons horizontally
              children: [
                SizedBox(
                  width: 150, // Set a fixed width for the buttons
                  child: ElevatedButton(
                    onPressed: () {
                      checkLoginStatus(context, onRequestCallPressed);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue), // Adding border
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Adding border radius
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call), // Add the call icon
                        SizedBox(
                            width: 5), // Add some spacing between icon and text
                        Text(
                          'Request Call',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    width: 5), // Add a SizedBox with width 5 for separation
                SizedBox(
                  width: 75, // Set a fixed width for the buttons
                  child: ElevatedButton(
                    onPressed: () {
                      checkLoginStatus(context, onMakeCallPressed);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue), // Adding border
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Adding border radius
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call), // Add the call icon
                        SizedBox(
                            width: 5), // Add some spacing between icon and text
                        Text(
                          'C',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    width: 5), // Add a SizedBox with width 5 for separation
                SizedBox(
                  width: 75, // Set a fixed width for the buttons
                  child: ElevatedButton(
                    onPressed: () {
                      checkLoginStatus(context, onWhatsappPressed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors
                          .green, // Green background color for WhatsApp button
                      foregroundColor: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Adding border radius
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(
                        //   Icons.whatshot, // WhatsApp icon
                        //   size: 20, // Adjust the size of the icon
                        // ),
                        Icon(
                          Ionicons.logo_whatsapp,
                          size: 20,
                        ),
                        SizedBox(
                            width: 5), // Add some spacing between icon and text
                        Text(
                          'W',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> checkLoginStatus(
      BuildContext context, VoidCallback callback) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      callback(); // Invoke the callback function
    }
  }
}

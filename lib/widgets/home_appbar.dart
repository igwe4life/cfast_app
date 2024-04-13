import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shop_example/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shop_example/screens/profile_page.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          String welcomeMessage = snapshot.data ?? '';
          return GestureDetector(
            onTap: () {
              // Navigate to the profile screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    backgroundColor: kcontentColor,
                    padding: const EdgeInsets.all(15),
                  ),
                  iconSize: 30,
                  icon: Image.asset(
                    'assets/logo.png',
                    height: 35,
                    width: 120,
                  ),
                ),
                Text(
                  welcomeMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    color: kprimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else {
          // You can return a loading indicator or an empty widget here while waiting for the data
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<String> _getUserInfo() async {
    final storage = FlutterSecureStorage();
    String? userName = await storage.read(key: 'name');
    int isLoggedIn = int.parse(await storage.read(key: 'isLoggedIn') ?? '0');

    if (isLoggedIn == 1) {
      return 'Welcome ${userName ?? 'User'}';
    } else {
      return 'Welcome User';
    }
  }
}

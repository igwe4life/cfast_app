import 'package:flutter/material.dart';
import 'package:shop_cfast/models/category.dart';
import 'package:shop_cfast/screens/CategoryDetailScreen.dart';
//import 'package:shop_example/screens/CatListView.dart'; // Import the CatListView screen
import 'CatListView.dart';

class Categories extends StatelessWidget {
  const Categories({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: GridView.count(
        crossAxisCount: 4, // 4 columns
        crossAxisSpacing: 15.0, // spacing between columns
        mainAxisSpacing: 20.0, // spacing between rows
        children: List.generate(categories.length, (index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatListView(
                    // title: categories[index].title,
                    // image: categories[index].image,
                    catname: categories[index].title,
                    catId: 0, parentId: 0,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(
                        categories[index].image,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  categories[index].title,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          );
        }),
      ),
    );
  }
}

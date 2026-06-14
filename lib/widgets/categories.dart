import 'package:flutter/material.dart';
import 'package:shop_cfast/models/category.dart';
import 'CatListView.dart';

class Categories extends StatelessWidget {
  const Categories({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 264,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.92,
        children: List.generate(categories.length, (index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatListView(
                    catname: categories[index].title,
                    catId: 0,
                    parentId: 0,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(categories[index].image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    categories[index].title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 8.5,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';


class ProductAppBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  const ProductAppBar({
    Key? key,
    required this.isFavorite,
    required this.onFavoritePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
            ),
            icon: const Icon(Icons.share),
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? Colors.red
                  : null, // Optional: Change icon color when favorited
            ),
            onPressed: onFavoritePressed, // Use the provided callback
          ),
        ],
      ),
    );
  }
}

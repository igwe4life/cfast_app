import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shop_cfast/constants.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:intl/intl.dart';

class ProductInfo extends StatelessWidget {
  final Product product;

  const ProductInfo({Key? key, required this.product}) : super(key: key);

  // Parse date and time strings
  DateTime parseDateTime(String date, String time) {
    final parsedDate = DateFormat("MMM d, yyyy").parse(date);
    final parsedTime = DateFormat("h:mm a").parse(time);
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds} secs ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} mins ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      final dateFormat = DateFormat("dd MMM yyyy");
      return dateFormat.format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Icon(
        //   Ionicons.locate_outline,
        //   size: 64,
        // ),
        Text(
          "${product.location}, ${product.date} ${product.time}",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          product.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.price ??
                      'Price not available', // Use a default value if product.price is null
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // This section seems to be commented out, you can uncomment it if needed.
                    // Container(
                    //   width: 50,
                    //   height: 20,
                    //   decoration: BoxDecoration(
                    //     color: kprimaryColor,
                    //     borderRadius: BorderRadius.circular(15),
                    //   ),
                    //   alignment: Alignment.center,
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 5,
                    //     vertical: 2,
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       const Icon(
                    //         Ionicons.star,
                    //         size: 13,
                    //         color: Colors.white,
                    //       ),
                    //       const SizedBox(width: 3),
                    //       Text(
                    //         product.rate.toString(),
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 13,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       )
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(width: 5),
                    // Text(
                    //   "${product.location}, ${product.date} ${product.time}",
                    //   style: const TextStyle(
                    //     color: Colors.grey,
                    //     fontSize: 14,
                    //   ),
                    // ),
                  ],
                ),
                // const SizedBox(height: 10),
              ],
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

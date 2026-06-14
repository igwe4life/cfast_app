import 'package:flutter/material.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:intl/intl.dart';

class ProductInfo extends StatelessWidget {
  final Product product;
  final String? apiCityName;
  final String? apiCreatedAt;

  const ProductInfo({
    Key? key,
    required this.product,
    this.apiCityName,
    this.apiCreatedAt,
  }) : super(key: key);

  String _formatPostedLabel() {
    final parsedDate = _parsePostedDate();
    if (parsedDate == null) {
      return product.time.isNotEmpty ? product.time : 'Recently posted';
    }

    return formatTimeAgo(parsedDate.toLocal());
  }

  DateTime? _parsePostedDate() {
    if (apiCreatedAt != null && apiCreatedAt!.isNotEmpty) {
      final parsed = DateTime.tryParse(apiCreatedAt!);
      if (parsed != null) return parsed;
    }
    final rawDate = product.date.trim();
    final rawTime = product.time.trim();

    for (final value in <String>[
      rawDate,
      '$rawDate $rawTime'.trim(),
    ]) {
      if (value.isEmpty) continue;

      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }

    final knownFormats = <DateFormat>[
      DateFormat("MMM d, yyyy h:mm a"),
      DateFormat("MMM d, yyyy"),
      DateFormat("d MMM y"),
      DateFormat("dd MMM yyyy"),
    ];

    for (final formatter in knownFormats) {
      try {
        return formatter.parseStrict('$rawDate $rawTime'.trim());
      } catch (_) {
        try {
          return formatter.parseStrict(rawDate);
        } catch (_) {}
      }
    }

    return null;
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 45) {
      return "Just posted";
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return "$minutes ${minutes == 1 ? 'min' : 'mins'} ago";
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return "$hours ${hours == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return "$days ${days == 1 ? 'day' : 'days'} ago";
    } else {
      final dateFormat = DateFormat("d MMM y");
      return dateFormat.format(dateTime);
    }
  }

  String _formatPriceLabel() {
    final price = product.price.trim();
    if (price.isEmpty || price.toLowerCase() == 'price on request') {
      return 'Price on request';
    }

    final normalized = price.replaceAll(',', '').trim();
    final numericValue = num.tryParse(normalized);
    if (numericValue == null) {
      return price.startsWith('\u20A6') ? price : '\u20A6$price';
    }

    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '\u20A6',
      decimalDigits: 0,
    ).format(numericValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Icon(
        //   Icons.location_on,
        //   size: 64,
        // ),
        Text(
          "${(apiCityName ?? product.location).isEmpty ? 'Location not set' : (apiCityName ?? product.location)} - ${_formatPostedLabel()}",
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
                  _formatPriceLabel(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
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
                    //         Icons.star,
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

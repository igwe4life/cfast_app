import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/screens/product_screen.dart';

import '../constants.dart';

class GridSimilar extends StatefulWidget {
  final String catURL;
  final String productId;

  const GridSimilar({
    Key? key,
    required this.catURL,
    required this.productId,
  }) : super(key: key);

  @override
  State<GridSimilar> createState() => _GridSimilarState();
}

class _GridSimilarState extends State<GridSimilar>
    with AutomaticKeepAliveClientMixin {
  static const Color _powderBlueBorder = Color(0xFFB8D8F8);
  static const Map<String, String> _apiHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Content-Language': 'en',
    'X-AppType': 'docs',
    'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
  };
  static final Map<String, Future<List<Product>>> _similarProductsCache =
      <String, Future<List<Product>>>{};

  late Future<List<Product>> _futureProducts;

  String get _cacheKey => '${widget.catURL}:${widget.productId}';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureProducts = _getCachedProducts();
  }

  @override
  void didUpdateWidget(covariant GridSimilar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catURL != widget.catURL ||
        oldWidget.productId != widget.productId) {
      _futureProducts = _getCachedProducts();
    }
  }

  Future<List<Product>> _getCachedProducts() {
    return _similarProductsCache.putIfAbsent(_cacheKey, () {
      return fetchDataFromApi().catchError((Object error) {
        _similarProductsCache.remove(_cacheKey);
        throw error;
      });
    });
  }

  Future<List<Product>> fetchDataFromApi() async {
    final uri = Uri.parse('$baseUrl/api/posts').replace(
      queryParameters: {
        'op': 'similar',
        'postId': widget.productId,
        'categoryId': widget.catURL,
        'perPage': '8',
      },
    );

    final response = await http.get(uri, headers: _apiHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to load similar ads');
    }

    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    final List<dynamic> data =
        (jsonResponse['result']?['data'] as List<dynamic>?) ?? <dynamic>[];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_productFromApiItem)
        .where((product) => product.classID != widget.productId)
        .toList();
  }

  Product _productFromApiItem(Map<String, dynamic> item) {
    final rawPrice = item['price'];
    final city = item['city'];
    final productId = item['id']?.toString() ?? '';
    final itemUrl = _fullProductUrl(
      item['url']?.toString() ?? item['slug']?.toString() ?? productId,
      productId,
    );

    return Product(
      title: item['title']?.toString() ?? 'Untitled product',
      description:
          item['description']?.toString() ?? item['title']?.toString() ?? '',
      image: item['listing_image']?.toString() ?? '',
      price: rawPrice == null || rawPrice.toString().isEmpty
          ? 'Price on request'
          : rawPrice.toString(),
      date: item['created_at']?.toString() ?? '',
      time: item['created_at_formatted']?.toString() ?? '',
      itemUrl: itemUrl,
      classID: productId,
      location: city is Map<String, dynamic>
          ? city['name']?.toString() ?? ''
          : item['location']?.toString() ?? '',
      catURL:
          item['category_id']?.toString() ?? item['catURL']?.toString() ?? '',
    );
  }

  String _fullProductUrl(String rawUrl, String productId) {
    final value = rawUrl.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final path = value.startsWith('/') ? value.substring(1) : value;
    if (path == productId) {
      return '$baseUrl/$path';
    }
    if (productId.isEmpty || path.endsWith('/$productId')) {
      return '$baseUrl/$path';
    }

    return '$baseUrl/$path/$productId';
  }

  void _refreshData() {
    setState(() {
      _similarProductsCache.remove(_cacheKey);
      _futureProducts = fetchDataFromApi();
      _similarProductsCache[_cacheKey] = _futureProducts;
    });
  }

  String _formatPriceLabel(String price) {
    if (price.isEmpty || price.toLowerCase() == 'price on request') {
      return 'Price on request';
    }

    final normalized = price.replaceAll(',', '').trim();
    final numericValue = num.tryParse(normalized);
    if (numericValue == null) {
      return price;
    }

    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '\u20A6',
      decimalDigits: 0,
    ).format(numericValue);
  }

  String _formatPostedLabel(Product product) {
    final parsedDate = DateTime.tryParse(product.date);
    if (parsedDate == null) {
      return product.time.isNotEmpty ? product.time : 'Recently posted';
    }

    final diff = DateTime.now().difference(parsedDate.toLocal());
    if (diff.inSeconds < 45) {
      return 'Just posted';
    }
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }

    return DateFormat('d MMM y').format(parsedDate.toLocal());
  }

  double _imageAspectRatioForIndex(int index) {
    const pattern = <double>[0.86, 1.1, 0.94, 1.2, 0.9, 1.05];
    return pattern[index % pattern.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load similar ads right now.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No similar ads available yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final products = snapshot.data!;

        return StaggeredGridView.countBuilder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          itemCount: products.length,
          itemBuilder: (_, index) =>
              _buildGridItem(context, products[index], index),
          staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
        );
      },
    );
  }

  Widget _buildGridItem(BuildContext context, Product product, int index) {
    final imageAspectRatio = _imageAspectRatioForIndex(index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductScreen(product: product)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _powderBlueBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: product.image.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: _powderBlueBorder, width: 2),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPriceLabel(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F5BFF),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location.isEmpty
                              ? 'Location not set'
                              : product.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatPostedLabel(product),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    ],
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

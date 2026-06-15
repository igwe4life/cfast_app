import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop_cfast/models/product.dart';
import 'package:shop_cfast/screens/product_screen.dart';
import 'package:shop_cfast/widgets/CustomBannerAd.dart';

import '../constants.dart';
import '../services/product_storage.dart';

class _InlineAdMarker {
  const _InlineAdMarker();
}

class GridHomeController {
  VoidCallback? _loadMoreIfNeeded;
  Future<void> Function()? _refresh;

  void _bind({
    required VoidCallback loadMoreIfNeeded,
    required Future<void> Function() refresh,
  }) {
    _loadMoreIfNeeded = loadMoreIfNeeded;
    _refresh = refresh;
  }

  void _unbind() {
    _loadMoreIfNeeded = null;
    _refresh = null;
  }

  void loadMoreIfNeeded() {
    _loadMoreIfNeeded?.call();
  }

  Future<void> refresh() async {
    await _refresh?.call();
  }
}

class GridHome extends StatefulWidget {
  final GridHomeController? controller;

  const GridHome({Key? key, this.controller}) : super(key: key);

  @override
  State<GridHome> createState() => _GridHomeState();
}

class _GridHomeState extends State<GridHome> {
  static const Color _powderBlueBorder = Color(0xFFB8D8F8);
  static const int _limit = 10;
  static const int _inlineAdProductInterval = 20;
  static const Map<String, String> _apiHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Content-Language': 'en',
    'X-AppType': 'docs',
    'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
  };

  final List<Product> _products = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(
      loadMoreIfNeeded: _handleAutoLoadTrigger,
      refresh: _refreshFromPull,
    );
    _primeProducts();
  }

  @override
  void dispose() {
    widget.controller?._unbind();
    super.dispose();
  }

  Future<List<Product>> fetchDataFromApi({int? offset}) async {
    final requestOffset = offset ?? _offset;

    try {
      final uri = Uri.parse('$baseUrl/api/posts').replace(
        queryParameters: {
          'op': 'null',
          'postId': '0',
          'distance': '0',
          'sort': 'created_at',
          'perPage': '$_limit',
          'page': '${(requestOffset ~/ _limit) + 1}',
        },
      );
      final response = await http.get(uri, headers: _apiHeaders);

      if (response.statusCode != 200) {
        throw Exception('Failed to load data: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data =
          (jsonResponse['result']?['data'] as List<dynamic>?) ?? <dynamic>[];

      final products = data
          .whereType<Map<String, dynamic>>()
          .map(_productFromApiItem)
          .toList();

      if (requestOffset == 0 && products.isNotEmpty) {
        // Don't block rendering on cache persistence.
        ProductStorage.saveProducts(products);
      }

      return products;
    } catch (e) {
      print('Error fetching data: $e');

      if (requestOffset == 0) {
        final cachedProducts = await ProductStorage.getProducts();
        if (cachedProducts.isNotEmpty) {
          return cachedProducts;
        }
      }

      throw Exception('Failed to load trending products');
    }
  }

  Future<void> _primeProducts() async {
    final cachedProducts = await ProductStorage.getProducts();
    if (!mounted) return;

    if (cachedProducts.isNotEmpty) {
      setState(() {
        _products
          ..clear()
          ..addAll(_sortProducts(cachedProducts));
        _isInitialLoading = false;
        _errorMessage = null;
        _offset = 0;
        _hasMore = true;
      });
    }

    await _loadInitialProducts(showLoader: cachedProducts.isEmpty);
  }

  Future<void> _refreshFromPull() async {
    await _loadInitialProducts(showLoader: _products.isEmpty);
  }

  Future<void> _loadInitialProducts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isInitialLoading = true;
        _isRefreshing = false;
        _errorMessage = null;
        _offset = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _offset = 0;
        _hasMore = true;
        _errorMessage = null;
      });
    }

    try {
      final products = await fetchDataFromApi(offset: 0);
      if (!mounted) return;

      setState(() {
        _products
          ..clear()
          ..addAll(_sortProducts(products));
        _hasMore = products.length >= _limit;
        _lastUpdatedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      if (_products.isEmpty) {
        setState(() {
          _products.clear();
          _errorMessage = 'Unable to load trending products right now.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (showLoader) {
            _isInitialLoading = false;
          }
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextOffset = _offset + _limit;

    try {
      final moreProducts = await fetchDataFromApi(offset: nextOffset);
      if (!mounted) return;

      setState(() {
        if (moreProducts.isEmpty) {
          _hasMore = false;
        } else {
          _offset = nextOffset;
          _products
            ..addAll(moreProducts)
            ..sort(_compareProductsByDateDesc);
          _hasMore = moreProducts.length >= _limit;
          _lastUpdatedAt = DateTime.now();
        }
      });
    } catch (e) {
      print('Error loading more products: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Product _productFromApiItem(Map<String, dynamic> item) {
    debugPrint('ITEM_DEBUG: ${const JsonEncoder.withIndent('  ').convert(item)}');
    final rawPrice = item['price'];
    final city = item['city'];
    final productId = item['id']?.toString() ?? '';
    final itemUrl = _fullProductUrl(
      item['url']?.toString() ?? item['slug']?.toString() ?? productId,
      productId,
    );

    debugPrint('LOCATION_DEBUG city_name=${item['city_name']} city=${item['city']} location=${item['location']}');

    return Product(
      title: item['title']?.toString() ?? 'Untitled product',
      description:
          item['description']?.toString() ?? item['title']?.toString() ?? '',
      image: _extractImageUrl(item),
      price: rawPrice == null || rawPrice.toString().isEmpty
          ? 'Price on request'
          : rawPrice.toString(),
      date: item['created_at']?.toString() ?? '',
      time: item['created_at_formatted']?.toString() ?? '',
      itemUrl: itemUrl,
      classID: productId,
      location: item['city_name']?.toString() ?? (city is Map<String, dynamic>
          ? city['name']?.toString() ?? ''
          : item['location']?.toString() ?? ''),
      catURL:
          item['category_id']?.toString() ?? item['catURL']?.toString() ?? '',
    );
  }

  String _extractImageUrl(Map<String, dynamic> item) {
    final pictures = item['pictures'] as List? ?? [];
    if (pictures.isNotEmpty) {
      final pic = pictures.first as Map<String, dynamic>;
      final url = pic['filename_url_big']?.toString() ??
          pic['filename_url']?.toString() ??
          pic['filename_url_medium']?.toString() ??
          '';
      if (url.isNotEmpty) {
        final result = url.startsWith('/') ? '$baseUrl$url' : url;
        debugPrint('CFAST_IMAGES GridHome from pictures: $result');
        return result;
      }
    }
    for (final key in ['listing_image', 'image', 'photo_url', 'user_photo_url', 'picture_url']) {
      final val = item[key]?.toString() ?? '';
      if (val.isNotEmpty) {
        final result = val.startsWith('/') ? '$baseUrl$val' : val;
        debugPrint('CFAST_IMAGES GridHome from $key: $result');
        return result;
      }
    }
    debugPrint('CFAST_IMAGES GridHome no image found for: ${item['title']}');
    return '';
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

  void _retryLoading() {
    _loadInitialProducts();
  }

  void _handleAutoLoadTrigger() {
    if (_isInitialLoading || _errorMessage != null) return;
    loadMoreProducts();
  }

  List<Product> _sortProducts(List<Product> products) {
    final sortedProducts = List<Product>.from(products);
    sortedProducts.sort(_compareProductsByDateDesc);
    return sortedProducts;
  }

  int _compareProductsByDateDesc(Product a, Product b) {
    return b.date.compareTo(a.date);
  }

  bool _isAdSlot(int itemIndex) {
    return itemIndex > 0 && itemIndex % (_inlineAdProductInterval + 1) == 0;
  }

  String _formatUpdatedLabel(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);

    if (diff.inSeconds < 10) {
      return 'Updated just now';
    }
    if (diff.inMinutes < 1) {
      return 'Updated ${diff.inSeconds}s ago';
    }
    if (diff.inHours < 1) {
      return 'Updated ${diff.inMinutes}m ago';
    }

    return 'Updated ${diff.inHours}h ago';
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
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    return DateFormat('d MMM y').format(parsedDate.toLocal());
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

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retryLoading,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No trending products available yet.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retryLoading,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final feedEntries = _buildFeedEntries();
    final statusText = _isRefreshing
        ? 'Refreshing...'
        : _lastUpdatedAt == null
            ? null
            : _formatUpdatedLabel(_lastUpdatedAt!);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (statusText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            StaggeredGridView.countBuilder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              itemCount: feedEntries.length,
              itemBuilder: (context, index) {
                final entry = feedEntries[index];
                if (entry is Product) {
                  return _buildGridItem(context, entry, index);
                }
                return _buildInlineBanner(context);
              },
              staggeredTileBuilder: (index) {
                final entry = feedEntries[index];
                if (entry is Product) {
                  return const StaggeredTile.fit(1);
                }
                return const StaggeredTile.fit(2);
              },
            ),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SizedBox(height: _hasMore ? 28 : 8),
          ],
        ),
      ),
    );
  }

  List<Object> _buildFeedEntries() {
    final entries = <Object>[];
    for (var i = 0; i < _products.length; i++) {
      entries.add(_products[i]);
      final isLast = i == _products.length - 1;
      if (!isLast && (i + 1) % _inlineAdProductInterval == 0) {
        entries.add(const _InlineAdMarker());
      }
    }
    return entries;
  }

  Widget _buildInlineBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Advertisement',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sponsored placement',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const CustomBannerAd(),
        ],
      ),
    );
  }

  double _imageAspectRatioForIndex(int index) {
    const pattern = <double>[0.82, 1.12, 0.92, 1.24, 0.88, 1.04];
    return pattern[index % pattern.length];
  }

  Widget _buildGridItem(BuildContext context, Product product, int index) {
    final imageAspectRatio = _imageAspectRatioForIndex(index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(product: product),
          ),
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
                  : Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                              ? ''
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

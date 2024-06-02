import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductStorage {
  static const String _key = 'products';

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> productsJson =
        products.map((product) => jsonEncode(product.toJson())).toList();
    await prefs.setStringList(_key, productsJson);
  }

  static Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? productsJson = prefs.getStringList(_key);
    if (productsJson != null) {
      return productsJson
          .map((jsonString) => Product.fromJson(jsonDecode(jsonString)))
          .toList();
    } else {
      return [];
    }
  }

  static Future<Product?> getProductByClassID(String classID) async {
    final List<Product> products = await getProducts();
    for (Product product in products) {
      if (product.classID == classID) {
        return product;
      }
    }
    return null; // If no product with matching classID is found
  }
}

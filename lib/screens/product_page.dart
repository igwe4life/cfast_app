import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:shop_example/widgets/product_widgets/ads_grid.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  Future<List> fetchAds() async {
    final response = await http
        .get('https://blasanka.github.io/watch-ads/lib/data/ads.json' as Uri);

    List ads = [];
    if (response.statusCode == 200) {
      ads = json.decode(response.body);
    }
    return ads;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Watch ads"),
      ),
      body: FutureBuilder(
          future: fetchAds(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return Center(
                  child: Text('Try again'),
                );
              case ConnectionState.active:
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              case ConnectionState.done:
                if (snapshot.hasError)
                  return Center(child: Text('Check internet connection'));
                return AdsGrid(ads: snapshot.data);
            } // unreachable
          }),
    );
  }
}

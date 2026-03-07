import 'package:flutter/material.dart';

class AdCard extends StatelessWidget {
  const AdCard(this.ad, {super.key});

  final ad;

  Widget _buildImageWidget() {
    if (ad["imageUrl"] != null && ad["imageUrl"] != '') {
      return Image.network(ad["imageUrl"]);
    } else {
      return Image.network('https://uae.microless.com/cdn/no_image.jpg');
    }
  }

  Widget _buildTitleWidget() {
    if (ad["title"] != null && ad["title"] != '') {
      return Text(
        ad["title"],
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildPriceWidget() {
    if (ad["price"] != null && ad["price"] != '') {
      return Text("\$ ${ad["price"]}");
    } else {
      return const SizedBox();
    }
  }

  Widget _buildLocationWidget() {
    if (ad["location"] != null && ad["location"] != '') {
      return Row(
        children: <Widget>[
          const Icon(Icons.location_on),
          const SizedBox(
            width: 4.0,
          ),
          Expanded(child: Text(ad["location"]))
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildImageWidget(),
          _buildTitleWidget(),
          _buildPriceWidget(),
          _buildLocationWidget(),
        ],
      ),
    );
  }
}

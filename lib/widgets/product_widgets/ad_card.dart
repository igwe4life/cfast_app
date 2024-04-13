import 'package:flutter/material.dart';

class AdCard extends StatelessWidget {
  AdCard(this.ad);

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
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      return SizedBox();
    }
  }

  Widget _buildPriceWidget() {
    if (ad["price"] != null && ad["price"] != '') {
      return Text("\$ ${ad["price"]}");
    } else {
      return SizedBox();
    }
  }

  Widget _buildLocationWidget() {
    if (ad["location"] != null && ad["location"] != '') {
      return Row(
        children: <Widget>[
          Icon(Icons.location_on),
          SizedBox(
            width: 4.0,
          ),
          Expanded(child: Text(ad["location"]))
        ],
      );
    } else {
      return SizedBox();
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

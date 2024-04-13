import 'package:flutter/material.dart';
import 'package:shop_example/constants.dart';
import 'package:shop_example/models/product.dart';
import 'package:shop_example/widgets/product_widgets/CallButtonsBar.dart';
import 'package:shop_example/widgets/product_widgets/ChatActionsWidget.dart';
import 'package:shop_example/widgets/product_widgets/appbar.dart';
import 'package:shop_example/widgets/product_widgets/image_slider.dart';
import 'package:shop_example/widgets/product_widgets/information.dart';
import 'package:shop_example/widgets/product_widgets/product_desc.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int currentImage = 0;
  int currentColor = 0;
  int currentNumber = 1;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kcontentColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductAppBar(
                isFavorite: isFavorite,
                onFavoritePressed: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });
                },
              ),
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        widget.product.image), // Use product.image directly
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImageSlider(
                      onChange: (index) {
                        setState(() {
                          currentImage = index;
                        });
                      },
                      currentImage: currentImage,
                      image: widget.product.image,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Placeholder widgets for price, location, date, and time
                          Text(
                            'Price: \$${widget.product.price}', // Replace with your price data
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Location: ${widget.product.location}', // Replace with your location data
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Date: ${widget.product.date}', // Replace with your date data
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Time: ${widget.product.time}', // Replace with your time data
                            style: TextStyle(fontSize: 18),
                          ),
                          // Other widgets for product details...
                          // (Your existing widgets go here)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Rest of the widgets...
              // (Continue with your existing widgets)
            ],
          ),
        ),
      ),
    );
  }
}

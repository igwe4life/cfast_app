import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class DetailsPage extends StatefulWidget {
  final Map<String, dynamic> item;

  // final String url;
  // final String title;
  final int index;

  const DetailsPage({Key? key, required this.item, required this.index})
      : super(key: key);

  //const DetailViewBody({Key? key, required this.item}) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  List imgList = [
    'https://i.dlpng.com/static/png/6838599_preview.png',
    'https://i.dlpng.com/static/png/6838599_preview.png',
    'https://i.dlpng.com/static/png/6838599_preview.png',
    'https://i.dlpng.com/static/png/6838599_preview.png',
  ];
  int _current = 0;

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Details',
            style: TextStyle(
                fontFamily: 'OpenSansLight',
                fontSize: 26,
                color: Theme.of(context).textTheme.headline1!.color),
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).canvasColor,
        leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ),
      body: Container(
        height: height,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Hero(
                tag: "product-image+${widget.index}",
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  height: 200.0,
                  alignment: Alignment.topCenter,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(
                            widget.item['image'] ??
                                'https://i.dlpng.com/static/png/6838599_preview.png',
                          ),
                          fit: BoxFit.contain)),
                ),
              ),
              CarouselSlider(
                options: CarouselOptions(
                    height: 200.0,
                    initialPage: 0,
                    reverse: false,
                    autoPlay: false,
                    enableInfiniteScroll: false,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index, fn) {
                      setState(() {
                        _current = index;
                      });
                    }),
                items: imgList.map((imgUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: map<Widget>(imgList, (index, url) {
                  return Container(
                    width: 30.0,
                    height: 2.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10.0),
                      color:
                          _current == index ? Colors.deepPurple : Colors.grey,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

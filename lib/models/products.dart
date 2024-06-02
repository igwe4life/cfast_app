class Products {
  final String title;
  final String description;
  final String image;
  final double price;
  final String date;
  final String time;
  final String itemUrl;
  final String classID;
  final String location;
  final String catURL;

  Products({
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.date,
    required this.time,
    required this.itemUrl,
    required this.classID,
    required this.location,
    required this.catURL,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'price': price,
      'date': date,
      'time': time,
      'itemUrl': itemUrl,
      'classID': classID,
      'location': location,
      'catURL': catURL,
    };
  }

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      title: json['title'],
      description: json['description'],
      image: json['image'],
      price: json['price'],
      date: json['date'],
      time: json['time'],
      itemUrl: json['itemUrl'],
      classID: json['classID'],
      location: json['location'],
      catURL: json['catURL'],
    );
  }
}

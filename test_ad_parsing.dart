import 'dart:convert';

class Ad {
  final int postId;
  final int? userId;
  final int categoryId;
  final String title;
  final String price;
  final String contactName;
  final String email;
  final String phone;
  final String createdAt;
  final String userPhotoUrl;
  final String? photoUrl;

  Ad({
    required this.postId,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.price,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.userPhotoUrl,
    required this.photoUrl,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      postId: json['post_id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      title: json['title'],
      price: json['price'],
      contactName: json['contact_name'],
      email: json['email'],
      phone: json['phone'],
      createdAt: json['created_at'],
      userPhotoUrl: json['user_photo_url'],
      photoUrl: json['photo_url'],
    );
  }
}

void main() {
  // Simulating API response where numbers are strings
  String jsonResponse = '''
  [
    {
      "post_id": "1001",
      "user_id": "50",
      "category_id": "5",
      "title": "Test Ad",
      "price": "5000",
      "contact_name": "John Doe",
      "email": "john@example.com",
      "phone": "1234567890",
      "created_at": "2023-10-27 10:00:00",
      "user_photo_url": "http://example.com/user.jpg",
      "photo_url": "http://example.com/ad.jpg"
    }
  ]
  ''';

  try {
    List<dynamic> data = json.decode(jsonResponse);
    List<Ad> ads = data.map((ad) => Ad.fromJson(ad)).toList();
    print('Successfully parsed ${ads.length} ads.');
  } catch (e) {
    print('Error parsing ads: $e');
  }
}

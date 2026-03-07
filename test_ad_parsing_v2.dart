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
      postId: int.tryParse(json['post_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()),
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      price: json['price'].toString(),
      contactName: json['contact_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] ?? '',
      userPhotoUrl: json['user_photo_url'] ?? '',
      photoUrl: json['photo_url'],
    );
  }
}

void main() {
  print('--- Testing Ad Parsing with Mixed Types ---');

  // Simulating API response with strings for integers
  String jsonResponseMixed = '''
  [
    {
      "post_id": "1001",
      "user_id": "50",
      "category_id": "5",
      "title": "String Id Ad",
      "price": "5000",
      "contact_name": "John Doe",
      "email": "john@example.com",
      "phone": "1234567890",
      "created_at": "2023-10-27 10:00:00",
      "user_photo_url": "http://example.com/user.jpg",
      "photo_url": "http://example.com/ad.jpg"
    },
    {
      "post_id": 1002,
      "user_id": 51,
      "category_id": 6,
      "title": "Int Id Ad",
      "price": 6000,
      "contact_name": "Jane Doe",
      "email": "jane@example.com",
      "phone": "0987654321",
      "created_at": "2023-10-28 10:00:00",
      "user_photo_url": "http://example.com/user2.jpg",
      "photo_url": null
    }
  ]
  ''';

  try {
    List<dynamic> data = json.decode(jsonResponseMixed);
    List<Ad> ads = data.map((ad) => Ad.fromJson(ad)).toList();
    
    print('Successfully parsed ${ads.length} ads.');
    
    for (var ad in ads) {
      print('Parsed Ad: ${ad.title}, PostID: ${ad.postId} (Type: ${ad.postId.runtimeType}), UserID: ${ad.userId} (Type: ${ad.userId.runtimeType})');
      if (ad.postId is! int || (ad.userId != null && ad.userId is! int)) {
          throw Exception('Type check failed for ${ad.title}');
      }
    }
    print('SUCCESS: All ads parsed correctly with correct types.');

  } catch (e) {
    print('FAILURE: Error parsing ads: $e');
  }
}

import 'package:http/http.dart' as http;

class Package {
  final int id;
  final String name;
  final String shortName; // e.g. "Free", "Premium"
  final String price;
  final String currencyCode;
  final int? promoDuration;
  final int? duration;
  final int? picturesLimit;
  final String description;
  final int recommended;
  final Map<String, dynamic>? currency;

  Package({
    required this.id,
    required this.name,
    required this.shortName,
    required this.price,
    required this.currencyCode,
    this.promoDuration,
    this.duration,
    this.picturesLimit,
    required this.description,
    required this.recommended,
    this.currency,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
      price: json['price'].toString(),
      currencyCode: json['currency_code'] ?? 'NGN',
      promoDuration: int.tryParse(json['promo_duration'].toString()),
      duration: int.tryParse(json['duration'].toString()),
      picturesLimit: int.tryParse(json['pictures_limit'].toString()),
      description: json['description_string'] ?? json['description'] ?? '',
      recommended: int.tryParse(json['recommended'].toString()) ?? 0,
      currency: json['currency'],
    );
  }
}

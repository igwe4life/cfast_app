class Products {
  final int id;
  final String country_code;
  final int user_id;
  final int category_id;
  final String title;
  final String description;
  final String email;
  final String phone;
  final String created_at_formatted;
  final String contact_name;

  Products({
    required this.id,
    required this.country_code,
    required this.user_id,
    required this.category_id,
    required this.title,
    required this.description,
    required this.email,
    required this.phone,
    required this.created_at_formatted,
    required this.contact_name,
  });
}

class Category {
  final String title;
  final String image;

  Category({
    required this.title,
    required this.image,
  });
}

final List<Category> categories = [
  Category(title: "Vehicles", image: "assets/cars.png"),
  Category(title: "Mobiles", image: "assets/mobile.jpg"),
  Category(title: "Electronics", image: "assets/pc.jpg"),
  Category(title: "Furniture", image: "assets/living-room.png"),
  Category(title: "Property", image: "assets/house.png"),
  Category(title: "Pets", image: "assets/pets.png"),
  Category(title: "Fashion", image: "assets/shoes.jpg"),
  Category(title: "Beauty", image: "assets/beauty2.png"),
  Category(title: "Jobs", image: "assets/job-search.png"),
  Category(title: "Services", image: "assets/profession.png"),
  Category(title: "Learning", image: "assets/online-course.png"),
  Category(title: "Events", image: "assets/people.png"),
];

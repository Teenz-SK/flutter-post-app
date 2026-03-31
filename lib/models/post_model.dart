// Model class for Post
// This helps us convert API JSON into Dart object

class PostModel {
  final int id;
  final String title;
  final String body;

  // Constructor
  PostModel({
    required this.id,
    required this.title,
    required this.body,
  });

  // Convert JSON → Dart Object
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}
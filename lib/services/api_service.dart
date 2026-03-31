import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class ApiService {
  final String baseUrl = "https://jsonplaceholder.typicode.com/posts";

  Future<List<PostModel>> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Accept": "application/json", "User-Agent": "Flutter App"},
      );

      print("STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        List jsonData = json.decode(response.body);

        return jsonData.map((e) => PostModel.fromJson(e)).toList();
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("ERROR: $e");
      throw Exception("Failed to load posts");
    }
  }
}

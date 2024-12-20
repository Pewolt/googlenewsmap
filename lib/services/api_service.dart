// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../models/publisher.dart';
import '../models/topic.dart';

class ApiService {
  static const String baseUrl = 'https://maptimes.peterwolters.org/api/v01'; // Ersetze durch deine tatsächliche API-URL

  Future<List<Publisher>> fetchPublishers() async {
    final response = await http.get(Uri.parse('$baseUrl/publishers'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Publisher> publishers = [];

      for (var item in data['items']) {
        publishers.add(Publisher.fromJson(item));
      }
      return publishers;
    } else {
      throw Exception('Failed to load publishers');
    }
  }

  Future<List<Article>> fetchNews({int? publisherId}) async {
    // Wir bauen die URL dynamisch, falls ein Publisher-Filter vorhanden ist.
    Uri url;
    if (publisherId != null) {
      // Die API erwartet laut vorherigen Infos ggf. einen Parameter publishers
      // als Liste oder einzelnen Wert. Prüfe die Doku deiner API.
      // Hier ein Beispiel mit einem einzelnen Publisher-Filter:
      url = Uri.parse('$baseUrl/news?publishers=$publisherId');
    } else {
      url = Uri.parse('$baseUrl/news');
    }

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Article> articles = [];
      for (var item in data['items']) {
        articles.add(Article.fromJson(item));
      }
      return articles;
    } else {
      throw Exception('Failed to load news');
    }
  }
}

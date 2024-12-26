// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';
import '../models/publisher.dart';
import '../models/topic.dart';
import '../models/publishers_articles_list_response.dart';

class ApiService {
  static const String baseUrl = 'https://maptimes.peterwolters.org/api/v01'; // Ersetze durch deine tatsächliche API-URL

  Future<List<Publisher>> fetchPublishers({
    String? country,
  }) async {
    // Baue die URL mit optionalen Parametern
    final uri = Uri.parse('$baseUrl/publishers${country != null ? "?country=$country" : ""}');
    final response = await http.get(uri);

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

  Future<List<Article>> fetchNews({
    int? publisherId,
    String? keywords,
    List<int>? topics,
    String? country,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // Erstelle Query-Parameter dynamisch
    final queryParams = <String, String>{};

    if (publisherId != null) queryParams['publishers'] = publisherId.toString();
    if (keywords != null && keywords.isNotEmpty) queryParams['keywords'] = keywords;
    if (topics != null && topics.isNotEmpty) queryParams['topics'] = topics.join(',');
    if (country != null && country.isNotEmpty) queryParams['country'] = country;
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();

    final uri = Uri.parse('$baseUrl/news').replace(queryParameters: queryParams);
    final response = await http.get(uri);

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

  Future<List<Topic>> fetchTopics() async {
    final response = await http.get(Uri.parse('$baseUrl/topics'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Topic> topics = [];
      for (var item in data['items']) {
        topics.add(Topic.fromJson(item));
      }
      return topics;
    } else {
      throw Exception('Failed to load topics');
    }
  }

  Future<List<String>> fetchAutocompleteSuggestions(String query) async {
    final uri = Uri.parse('$baseUrl/search/autocomplete?q=$query');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> suggestions = data['suggestions'];
      return suggestions.map((s) => s.toString()).toList();
    } else {
      throw Exception('Failed to load autocomplete suggestions');
    }
  }

  Future<PublishersArticlesListResponse> searchPublishersWithArticles({
    String? keywords,
    List<int>? topics,
    List<int>? publisherIds,
    String? country,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 200,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (keywords != null && keywords.isNotEmpty) {
      queryParams['keywords'] = keywords;
    }
    if (topics != null && topics.isNotEmpty) {
      // FastAPI akzeptiert Wiederholungen: topics=1&topics=2 oder ANY(...)?
      // Hier nehmen wir an, du kannst Komma-separierte IDs senden:
      queryParams['topics'] = topics.join(',');
    }
    if (publisherIds != null && publisherIds.isNotEmpty) {
      queryParams['publishers'] = publisherIds.join(',');
    }
    if (country != null && country.isNotEmpty) {
      queryParams['country'] = country.replaceAll(" ", "");
    }
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);
    print('SEARCH-URL: $uri');
    final response = await http.get(uri);

    print('SEARCH-RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      print('SEARCH-RESPONSE-MAP: $jsonMap');
      return PublishersArticlesListResponse.fromJson(jsonMap);
    } else {
      print('SEARCH-RESPONSE-STATUS: ${response.statusCode}');
      throw Exception('Fehler beim Aufrufen von /api/v01/search: ${response.statusCode}');
    }
  }
}

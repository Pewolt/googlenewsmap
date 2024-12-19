// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publisher.dart';

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
}

// lib/models/article.dart

import 'package:intl/intl.dart';

import 'publisher.dart';
import 'topic.dart';

class Article {
  final int id;
  final String title;
  final String link;
  final DateTime? pubDate;
  final Publisher? publisher;
  final Topic? topic;

  Article({
    required this.id,
    required this.title,
    required this.link,
    this.pubDate,
    this.publisher,
    this.topic,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['pub_date'] != null) {
      parsedDate = DateTime.tryParse(json['pub_date']);
    }

    return Article(
      id: json['id'],
      title: json['title'],
      link: json['link'],
      pubDate: parsedDate,
      publisher: json['publisher'] != null ? Publisher.fromJson(json['publisher']) : null,
      topic: json['topic'] != null ? Topic.fromJson(json['topic']) : null,
    );
  }

  String get formattedDate {
    if (pubDate == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(pubDate!);
  }
}

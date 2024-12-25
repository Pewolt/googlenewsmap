// lib/models/article.dart

import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'publisher.dart';
import 'topic.dart';

part 'article.g.dart';

@JsonSerializable()
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

  /// json_serializable generiert diese Methode
  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleToJson(this);

  String get formattedDate {
    if (pubDate == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(pubDate!);
  }
}

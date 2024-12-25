// lib/models/publisher_with_articles.dart

import 'package:maptimes/models/publisher.dart';
import 'package:maptimes/models/article.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publisher_with_articles.g.dart';

@JsonSerializable()
class PublisherWithArticles {
  final Publisher publisher;
  final List<Article> articles;

  PublisherWithArticles({
    required this.publisher,
    required this.articles,
  });

  factory PublisherWithArticles.fromJson(Map<String, dynamic> json) =>
      _$PublisherWithArticlesFromJson(json);

  Map<String, dynamic> toJson() => _$PublisherWithArticlesToJson(this);
}

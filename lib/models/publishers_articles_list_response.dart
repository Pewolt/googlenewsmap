// lib/models/publishers_articles_list_response.dart

import 'package:maptimes/models/publisher_with_articles.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publishers_articles_list_response.g.dart';

@JsonSerializable()
class PublishersArticlesListResponse {
  @JsonKey(name: 'total_publishers')
  final int totalPublishers;

  @JsonKey(name: 'total_articles')
  final int totalArticles;

  final int page;

  @JsonKey(name: 'page_size')
  final int pageSize;

  final List<PublisherWithArticles> items;

  PublishersArticlesListResponse({
    required this.totalPublishers,
    required this.totalArticles,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  factory PublishersArticlesListResponse.fromJson(Map<String, dynamic> json) =>
      _$PublishersArticlesListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PublishersArticlesListResponseToJson(this);
}

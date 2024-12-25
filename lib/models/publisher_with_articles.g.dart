// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publisher_with_articles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublisherWithArticles _$PublisherWithArticlesFromJson(
        Map<String, dynamic> json) =>
    PublisherWithArticles(
      publisher: Publisher.fromJson(json['publisher'] as Map<String, dynamic>),
      articles: (json['articles'] as List<dynamic>)
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublisherWithArticlesToJson(
        PublisherWithArticles instance) =>
    <String, dynamic>{
      'publisher': instance.publisher,
      'articles': instance.articles,
    };

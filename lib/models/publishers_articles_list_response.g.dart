// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publishers_articles_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishersArticlesListResponse _$PublishersArticlesListResponseFromJson(
        Map<String, dynamic> json) =>
    PublishersArticlesListResponse(
      totalPublishers: (json['total_publishers'] as num).toInt(),
      totalArticles: (json['total_articles'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => PublisherWithArticles.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublishersArticlesListResponseToJson(
        PublishersArticlesListResponse instance) =>
    <String, dynamic>{
      'total_publishers': instance.totalPublishers,
      'total_articles': instance.totalArticles,
      'page': instance.page,
      'page_size': instance.pageSize,
      'items': instance.items,
    };

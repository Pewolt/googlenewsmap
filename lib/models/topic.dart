// lib/models/topic.dart

class Topic {
  final int id;
  final String topicName;

  Topic({required this.id, required this.topicName});

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'],
      topicName: json['topic_name'],
    );
  }
}

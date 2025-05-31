class EducationalContent {
  final String id;
  final String title;
  final String content;
  final String category;

  EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  factory EducationalContent.fromMap(Map<String, dynamic> data, String id) {
    return EducationalContent(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'content': content, 'category': category};
  }
}

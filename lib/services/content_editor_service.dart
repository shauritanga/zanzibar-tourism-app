import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final contentEditorServiceProvider = Provider<ContentEditorService>((ref) => ContentEditorService());

enum ContentType { article, productDescription, siteDescription, tourDescription, announcement }

enum ContentStatus { draft, pending, approved, rejected, published }

class RichContent {
  final String id;
  final String title;
  final String content; // HTML content
  final String plainText; // Plain text version for search
  final ContentType type;
  final ContentStatus status;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final List<String> mediaIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewerId;
  final String? reviewerNotes;
  final DateTime? publishedAt;

  RichContent({
    required this.id,
    required this.title,
    required this.content,
    required this.plainText,
    required this.type,
    required this.status,
    required this.authorId,
    required this.authorName,
    required this.tags,
    required this.mediaIds,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerId,
    this.reviewerNotes,
    this.publishedAt,
  });

  factory RichContent.fromMap(Map<String, dynamic> map, String id) {
    return RichContent(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      plainText: map['plainText'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContentType.article,
      ),
      status: ContentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContentStatus.draft,
      ),
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mediaIds: List<String>.from(map['mediaIds'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewerId: map['reviewerId'],
      reviewerNotes: map['reviewerNotes'],
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'plainText': plainText,
      'type': type.name,
      'status': status.name,
      'authorId': authorId,
      'authorName': authorName,
      'tags': tags,
      'mediaIds': mediaIds,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewerId': reviewerId,
      'reviewerNotes': reviewerNotes,
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
    };
  }

  RichContent copyWith({
    String? id,
    String? title,
    String? content,
    String? plainText,
    ContentType? type,
    ContentStatus? status,
    String? authorId,
    String? authorName,
    List<String>? tags,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewerId,
    String? reviewerNotes,
    DateTime? publishedAt,
  }) {
    return RichContent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      type: type ?? this.type,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
      mediaIds: mediaIds ?? this.mediaIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

class ContentTemplate {
  final String id;
  final String name;
  final String description;
  final ContentType type;
  final String templateContent;
  final List<String> requiredFields;
  final Map<String, dynamic> defaultMetadata;

  ContentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.templateContent,
    required this.requiredFields,
    required this.defaultMetadata,
  });

  factory ContentTemplate.fromMap(Map<String, dynamic> map, String id) {
    return ContentTemplate(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContentType.article,
      ),
      templateContent: map['templateContent'] ?? '',
      requiredFields: List<String>.from(map['requiredFields'] ?? []),
      defaultMetadata: Map<String, dynamic>.from(map['defaultMetadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'templateContent': templateContent,
      'requiredFields': requiredFields,
      'defaultMetadata': defaultMetadata,
    };
  }
}

class ContentEditorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create new content
  Future<RichContent> createContent({
    required String title,
    required String content,
    required ContentType type,
    required String authorId,
    required String authorName,
    List<String> tags = const [],
    List<String> mediaIds = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final contentId = _uuid.v4();
      final plainText = _stripHtml(content);
      
      final richContent = RichContent(
        id: contentId,
        title: title,
        content: content,
        plainText: plainText,
        type: type,
        status: ContentStatus.draft,
        authorId: authorId,
        authorName: authorName,
        tags: tags,
        mediaIds: mediaIds,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('rich_content').doc(contentId).set(richContent.toMap());
      return richContent;
    } catch (e) {
      throw Exception('Failed to create content: $e');
    }
  }

  // Update content
  Future<RichContent> updateContent({
    required String contentId,
    String? title,
    String? content,
    List<String>? tags,
    List<String>? mediaIds,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final doc = await _firestore.collection('rich_content').doc(contentId).get();
      if (!doc.exists) {
        throw Exception('Content not found');
      }

      final existingContent = RichContent.fromMap(doc.data()!, doc.id);
      final plainText = content != null ? _stripHtml(content) : existingContent.plainText;

      final updatedContent = existingContent.copyWith(
        title: title,
        content: content,
        plainText: plainText,
        tags: tags,
        mediaIds: mediaIds,
        metadata: metadata,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('rich_content').doc(contentId).update(updatedContent.toMap());
      return updatedContent;
    } catch (e) {
      throw Exception('Failed to update content: $e');
    }
  }

  // Submit content for review
  Future<void> submitForReview(String contentId) async {
    try {
      await _firestore.collection('rich_content').doc(contentId).update({
        'status': ContentStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit for review: $e');
    }
  }

  // Approve content
  Future<void> approveContent({
    required String contentId,
    required String reviewerId,
    String? reviewerNotes,
    bool publish = false,
  }) async {
    try {
      final updateData = {
        'status': publish ? ContentStatus.published.name : ContentStatus.approved.name,
        'reviewerId': reviewerId,
        'reviewerNotes': reviewerNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (publish) {
        updateData['publishedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('rich_content').doc(contentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to approve content: $e');
    }
  }

  // Reject content
  Future<void> rejectContent({
    required String contentId,
    required String reviewerId,
    required String reviewerNotes,
  }) async {
    try {
      await _firestore.collection('rich_content').doc(contentId).update({
        'status': ContentStatus.rejected.name,
        'reviewerId': reviewerId,
        'reviewerNotes': reviewerNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject content: $e');
    }
  }

  // Publish content
  Future<void> publishContent(String contentId) async {
    try {
      await _firestore.collection('rich_content').doc(contentId).update({
        'status': ContentStatus.published.name,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to publish content: $e');
    }
  }

  // Get content by ID
  Future<RichContent?> getContent(String contentId) async {
    try {
      final doc = await _firestore.collection('rich_content').doc(contentId).get();
      if (!doc.exists) return null;

      return RichContent.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get content: $e');
    }
  }

  // Get content by author
  Stream<List<RichContent>> getContentByAuthor(String authorId) {
    return _firestore
        .collection('rich_content')
        .where('authorId', isEqualTo: authorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RichContent.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get content by status
  Stream<List<RichContent>> getContentByStatus(ContentStatus status) {
    return _firestore
        .collection('rich_content')
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RichContent.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get published content by type
  Stream<List<RichContent>> getPublishedContentByType(ContentType type) {
    return _firestore
        .collection('rich_content')
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: ContentStatus.published.name)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RichContent.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Search content
  Future<List<RichContent>> searchContent({
    required String query,
    ContentType? type,
    ContentStatus? status,
    int limit = 20,
  }) async {
    try {
      Query queryRef = _firestore.collection('rich_content');

      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.name);
      }

      if (status != null) {
        queryRef = queryRef.where('status', isEqualTo: status.name);
      }

      final snapshot = await queryRef.limit(limit).get();
      
      return snapshot.docs
          .map((doc) => RichContent.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((content) => 
              content.title.toLowerCase().contains(query.toLowerCase()) ||
              content.plainText.toLowerCase().contains(query.toLowerCase()) ||
              content.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }

  // Delete content
  Future<void> deleteContent(String contentId) async {
    try {
      await _firestore.collection('rich_content').doc(contentId).delete();
    } catch (e) {
      throw Exception('Failed to delete content: $e');
    }
  }

  // Create content template
  Future<ContentTemplate> createTemplate({
    required String name,
    required String description,
    required ContentType type,
    required String templateContent,
    List<String> requiredFields = const [],
    Map<String, dynamic> defaultMetadata = const {},
  }) async {
    try {
      final templateId = _uuid.v4();
      
      final template = ContentTemplate(
        id: templateId,
        name: name,
        description: description,
        type: type,
        templateContent: templateContent,
        requiredFields: requiredFields,
        defaultMetadata: defaultMetadata,
      );

      await _firestore.collection('content_templates').doc(templateId).set(template.toMap());
      return template;
    } catch (e) {
      throw Exception('Failed to create template: $e');
    }
  }

  // Get templates by type
  Future<List<ContentTemplate>> getTemplatesByType(ContentType type) async {
    try {
      final snapshot = await _firestore
          .collection('content_templates')
          .where('type', isEqualTo: type.name)
          .get();

      return snapshot.docs.map((doc) {
        return ContentTemplate.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get templates: $e');
    }
  }

  // Helper method to strip HTML tags
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  // Get content statistics
  Future<Map<String, int>> getContentStatistics() async {
    try {
      final snapshot = await _firestore.collection('rich_content').get();
      
      Map<String, int> stats = {
        'total': 0,
        'draft': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'published': 0,
      };

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'draft';
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }
}

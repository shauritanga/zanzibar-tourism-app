import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

enum SocialPlatform { facebook, twitter, instagram, whatsapp, email, link }

class UserProfile {
  final String userId;
  final String displayName;
  final String? bio;
  final String? avatar;
  final String? location;
  final List<String> interests;
  final Map<String, dynamic> socialLinks;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime joinedAt;
  final bool isVerified;
  final bool isPublic;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatar,
    this.location,
    required this.interests,
    required this.socialLinks,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.joinedAt,
    required this.isVerified,
    required this.isPublic,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      userId: id,
      displayName: map['displayName'] ?? '',
      bio: map['bio'],
      avatar: map['avatar'],
      location: map['location'],
      interests: List<String>.from(map['interests'] ?? []),
      socialLinks: Map<String, dynamic>.from(map['socialLinks'] ?? {}),
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      isPublic: map['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'bio': bio,
      'avatar': avatar,
      'location': location,
      'interests': interests,
      'socialLinks': socialLinks,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isVerified': isVerified,
      'isPublic': isPublic,
    };
  }
}

class SocialPost {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final List<String> images;
  final String? location;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final bool isPublic;
  final String? relatedItemId;
  final String? relatedItemType;

  SocialPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.images,
    this.location,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.createdAt,
    required this.isPublic,
    this.relatedItemId,
    this.relatedItemType,
  });

  factory SocialPost.fromMap(Map<String, dynamic> map, String id) {
    return SocialPost(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      location: map['location'],
      tags: List<String>.from(map['tags'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: map['isPublic'] ?? true,
      relatedItemId: map['relatedItemId'],
      relatedItemType: map['relatedItemType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'images': images,
      'location': location,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'relatedItemId': relatedItemId,
      'relatedItemType': relatedItemType,
    };
  }
}

class SocialComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final String? parentCommentId;

  SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    this.parentCommentId,
  });

  factory SocialComment.fromMap(Map<String, dynamic> map, String id) {
    return SocialComment(
      id: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: map['parentCommentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
    };
  }
}

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Profile Management
  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? avatar,
    String? location,
    List<String> interests = const [],
    Map<String, dynamic> socialLinks = const {},
  }) async {
    try {
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        bio: bio,
        avatar: avatar,
        location: location,
        interests: interests,
        socialLinks: socialLinks,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        joinedAt: DateTime.now(),
        isVerified: false,
        isPublic: true,
      );

      await _firestore.collection('user_profiles').doc(userId).set(profile.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      if (!doc.exists) return null;

      return UserProfile.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatar,
    String? location,
    List<String>? interests,
    Map<String, dynamic>? socialLinks,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;
      if (location != null) updateData['location'] = location;
      if (interests != null) updateData['interests'] = interests;
      if (socialLinks != null) updateData['socialLinks'] = socialLinks;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('user_profiles').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Social Posts
  Future<String> createPost({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    List<String> images = const [],
    String? location,
    List<String> tags = const [],
    bool isPublic = true,
    String? relatedItemId,
    String? relatedItemType,
  }) async {
    try {
      final postRef = _firestore.collection('social_posts').doc();
      
      final post = SocialPost(
        id: postRef.id,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        images: images,
        location: location,
        tags: tags,
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        createdAt: DateTime.now(),
        isPublic: isPublic,
        relatedItemId: relatedItemId,
        relatedItemType: relatedItemType,
      );

      await postRef.set(post.toMap());

      // Update user's post count
      await _firestore.collection('user_profiles').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      return postRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Stream<List<SocialPost>> getPosts({
    String? userId,
    int limit = 20,
    bool publicOnly = true,
  }) {
    Query query = _firestore.collection('social_posts');

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (publicOnly) {
      query = query.where('isPublic', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SocialPost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      final likeRef = _firestore
          .collection('social_posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await _firestore.collection('social_posts').doc(postId).update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('social_posts').doc(postId).update({
          'likesCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Failed to like/unlike post: $e');
    }
  }

  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('social_posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Comments
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('social_posts')
          .doc(postId)
          .collection('comments')
          .doc();

      final comment = SocialComment(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        likesCount: 0,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      await commentRef.set(comment.toMap());

      // Update post's comment count
      await _firestore.collection('social_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Stream<List<SocialComment>> getComments(String postId) {
    return _firestore
        .collection('social_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SocialComment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Following System
  Future<void> followUser(String followerId, String followeeId) async {
    try {
      final batch = _firestore.batch();

      // Add to follower's following list
      final followingRef = _firestore
          .collection('user_profiles')
          .doc(followerId)
          .collection('following')
          .doc(followeeId);

      batch.set(followingRef, {
        'userId': followeeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to followee's followers list
      final followerRef = _firestore
          .collection('user_profiles')
          .doc(followeeId)
          .collection('followers')
          .doc(followerId);

      batch.set(followerRef, {
        'userId': followerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update counts
      batch.update(_firestore.collection('user_profiles').doc(followerId), {
        'followingCount': FieldValue.increment(1),
      });

      batch.update(_firestore.collection('user_profiles').doc(followeeId), {
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String followerId, String followeeId) async {
    try {
      final batch = _firestore.batch();

      // Remove from following list
      batch.delete(_firestore
          .collection('user_profiles')
          .doc(followerId)
          .collection('following')
          .doc(followeeId));

      // Remove from followers list
      batch.delete(_firestore
          .collection('user_profiles')
          .doc(followeeId)
          .collection('followers')
          .doc(followerId));

      // Update counts
      batch.update(_firestore.collection('user_profiles').doc(followerId), {
        'followingCount': FieldValue.increment(-1),
      });

      batch.update(_firestore.collection('user_profiles').doc(followeeId), {
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  Future<bool> isFollowing(String followerId, String followeeId) async {
    try {
      final doc = await _firestore
          .collection('user_profiles')
          .doc(followerId)
          .collection('following')
          .doc(followeeId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Sharing
  Future<void> shareContent({
    required String title,
    required String text,
    String? url,
    SocialPlatform? platform,
  }) async {
    try {
      if (platform == null) {
        // Generic share
        await Share.share(
          '$text\n\n$url',
          subject: title,
        );
      } else {
        await _shareToSpecificPlatform(platform, title, text, url);
      }
    } catch (e) {
      throw Exception('Failed to share content: $e');
    }
  }

  Future<void> _shareToSpecificPlatform(
    SocialPlatform platform,
    String title,
    String text,
    String? url,
  ) async {
    String shareUrl;
    
    switch (platform) {
      case SocialPlatform.facebook:
        shareUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url ?? '')}';
        break;
      case SocialPlatform.twitter:
        shareUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url ?? '')}';
        break;
      case SocialPlatform.whatsapp:
        shareUrl = 'https://wa.me/?text=${Uri.encodeComponent('$text\n\n$url')}';
        break;
      case SocialPlatform.email:
        shareUrl = 'mailto:?subject=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent('$text\n\n$url')}';
        break;
      default:
        await Share.share('$text\n\n$url', subject: title);
        return;
    }

    final uri = Uri.parse(shareUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Search users
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      // Note: This is a simplified search. In production, you'd use a proper search service
      final snapshot = await _firestore
          .collection('user_profiles')
          .where('isPublic', isEqualTo: true)
          .limit(limit)
          .get();

      final users = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .where((user) => 
              user.displayName.toLowerCase().contains(query.toLowerCase()) ||
              (user.bio?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      return users;
    } catch (e) {
      return [];
    }
  }

  // Get user feed (posts from followed users)
  Stream<List<SocialPost>> getUserFeed(String userId, {int limit = 20}) {
    return _firestore
        .collection('user_profiles')
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      if (followingSnapshot.docs.isEmpty) {
        return <SocialPost>[];
      }

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      
      // Add user's own posts
      followingIds.add(userId);

      final postsSnapshot = await _firestore
          .collection('social_posts')
          .where('userId', whereIn: followingIds.take(10).toList()) // Firestore limit
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return postsSnapshot.docs.map((doc) {
        return SocialPost.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

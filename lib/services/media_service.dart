import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

enum MediaType { image, video, document }

class MediaFile {
  final String id;
  final String name;
  final String url;
  final String downloadUrl;
  final MediaType type;
  final int size;
  final String mimeType;
  final String uploadedBy;
  final DateTime uploadedAt;
  final Map<String, dynamic> metadata;

  MediaFile({
    required this.id,
    required this.name,
    required this.url,
    required this.downloadUrl,
    required this.type,
    required this.size,
    required this.mimeType,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.metadata,
  });

  factory MediaFile.fromMap(Map<String, dynamic> map, String id) {
    return MediaFile(
      id: id,
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      type: MediaType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MediaType.image,
      ),
      size: map['size'] ?? 0,
      mimeType: map['mimeType'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'downloadUrl': downloadUrl,
      'type': type.name,
      'size': size,
      'mimeType': mimeType,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'metadata': metadata,
    };
  }
}

class UploadProgress {
  final String id;
  final String fileName;
  final double progress;
  final bool isComplete;
  final String? error;
  final String? downloadUrl;

  UploadProgress({
    required this.id,
    required this.fileName,
    required this.progress,
    required this.isComplete,
    this.error,
    this.downloadUrl,
  });
}

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Upload image from gallery or camera
  Future<MediaFile?> uploadImage({
    required String userId,
    required ImageSource source,
    String folder = 'images',
    Map<String, dynamic> metadata = const {},
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      return await uploadFile(
        file: file,
        userId: userId,
        folder: folder,
        metadata: metadata,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<MediaFile>> uploadMultipleImages({
    required String userId,
    String folder = 'images',
    Map<String, dynamic> metadata = const {},
    Function(String, UploadProgress)? onProgress,
  }) async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return [];

      final List<MediaFile> uploadedFiles = [];

      for (final pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final uploadId = _uuid.v4();
        
        final mediaFile = await uploadFile(
          file: file,
          userId: userId,
          folder: folder,
          metadata: metadata,
          onProgress: (progress) {
            onProgress?.call(uploadId, progress);
          },
        );

        if (mediaFile != null) {
          uploadedFiles.add(mediaFile);
        }
      }

      return uploadedFiles;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Upload video
  Future<MediaFile?> uploadVideo({
    required String userId,
    required ImageSource source,
    String folder = 'videos',
    Map<String, dynamic> metadata = const {},
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      return await uploadFile(
        file: file,
        userId: userId,
        folder: folder,
        metadata: metadata,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Upload file from bytes (for web)
  Future<MediaFile?> uploadFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String folder = 'uploads',
    Map<String, dynamic> metadata = const {},
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      final fileId = _uuid.v4();
      final extension = path.extension(fileName);
      final storagePath = '$folder/$userId/$fileId$extension';
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(bytes);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(UploadProgress(
          id: fileId,
          fileName: fileName,
          progress: progress,
          isComplete: false,
        ));
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore
      final mediaFile = MediaFile(
        id: fileId,
        name: fileName,
        url: storagePath,
        downloadUrl: downloadUrl,
        type: _getMediaType(fileName),
        size: bytes.length,
        mimeType: _getMimeType(fileName),
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection('media_files').doc(fileId).set(mediaFile.toMap());

      onProgress?.call(UploadProgress(
        id: fileId,
        fileName: fileName,
        progress: 1.0,
        isComplete: true,
        downloadUrl: downloadUrl,
      ));

      return mediaFile;
    } catch (e) {
      onProgress?.call(UploadProgress(
        id: _uuid.v4(),
        fileName: fileName,
        progress: 0.0,
        isComplete: true,
        error: e.toString(),
      ));
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload file
  Future<MediaFile?> uploadFile({
    required File file,
    required String userId,
    String folder = 'uploads',
    Map<String, dynamic> metadata = const {},
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      final fileId = _uuid.v4();
      final fileName = path.basename(file.path);
      final extension = path.extension(fileName);
      final storagePath = '$folder/$userId/$fileId$extension';
      
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(UploadProgress(
          id: fileId,
          fileName: fileName,
          progress: progress,
          isComplete: false,
        ));
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      final fileSize = await file.length();

      // Save to Firestore
      final mediaFile = MediaFile(
        id: fileId,
        name: fileName,
        url: storagePath,
        downloadUrl: downloadUrl,
        type: _getMediaType(fileName),
        size: fileSize,
        mimeType: _getMimeType(fileName),
        uploadedBy: userId,
        uploadedAt: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection('media_files').doc(fileId).set(mediaFile.toMap());

      onProgress?.call(UploadProgress(
        id: fileId,
        fileName: fileName,
        progress: 1.0,
        isComplete: true,
        downloadUrl: downloadUrl,
      ));

      return mediaFile;
    } catch (e) {
      onProgress?.call(UploadProgress(
        id: _uuid.v4(),
        fileName: path.basename(file.path),
        progress: 0.0,
        isComplete: true,
        error: e.toString(),
      ));
      throw Exception('Failed to upload file: $e');
    }
  }

  // Get user's uploaded files
  Stream<List<MediaFile>> getUserFiles(String userId) {
    return _firestore
        .collection('media_files')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MediaFile.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get files by type
  Stream<List<MediaFile>> getFilesByType(String userId, MediaType type) {
    return _firestore
        .collection('media_files')
        .where('uploadedBy', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MediaFile.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Delete file
  Future<void> deleteFile(String fileId) async {
    try {
      // Get file info
      final doc = await _firestore.collection('media_files').doc(fileId).get();
      if (!doc.exists) {
        throw Exception('File not found');
      }

      final mediaFile = MediaFile.fromMap(doc.data()!, doc.id);

      // Delete from Storage
      await _storage.ref().child(mediaFile.url).delete();

      // Delete from Firestore
      await _firestore.collection('media_files').doc(fileId).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get file info
  Future<MediaFile?> getFile(String fileId) async {
    try {
      final doc = await _firestore.collection('media_files').doc(fileId).get();
      if (!doc.exists) return null;

      return MediaFile.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get file: $e');
    }
  }

  // Update file metadata
  Future<void> updateFileMetadata(String fileId, Map<String, dynamic> metadata) async {
    try {
      await _firestore.collection('media_files').doc(fileId).update({
        'metadata': metadata,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update file metadata: $e');
    }
  }

  // Get storage usage for user
  Future<int> getUserStorageUsage(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('media_files')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      int totalSize = 0;
      for (var doc in snapshot.docs) {
        totalSize += (doc.data()['size'] ?? 0) as int;
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Helper methods
  MediaType _getMediaType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension)) {
      return MediaType.image;
    } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension)) {
      return MediaType.video;
    } else {
      return MediaType.document;
    }
  }

  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

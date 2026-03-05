import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';

final fileAccessServiceProvider = Provider<FileAccessService>((ref) => FileAccessService());

class FileAccessService {
  /// Get user-specific documents box
  Future<Box<LocalDocument>> _getUserDocumentsBox(String uuid) async {
    try {
      return Hive.box<LocalDocument>('documents_$uuid');
    } catch (e) {
      // If box doesn't exist, open it
      return await Hive.openBox<LocalDocument>('documents_$uuid');
    }
  }
  /// Check if a file is still accessible (not expired)
  bool isFileAccessible(LocalDocument doc) {
    // If it's not a shared file, it's always accessible
    if (doc.isSharedFile != true || doc.expirationTime == null) {
      return true;
    }
    
    // Check if the file has expired
    return DateTime.now().isBefore(doc.expirationTime!);
  }

  /// Get time remaining until file expires
  Duration? getTimeRemaining(LocalDocument doc) {
    if (doc.isSharedFile != true || doc.expirationTime == null) {
      return null;
    }
    
    final now = DateTime.now();
    if (now.isAfter(doc.expirationTime!)) {
      return Duration.zero; // Already expired
    }
    
    return doc.expirationTime!.difference(now);
  }

  /// Check if file is expiring soon (within 24 hours)
  bool isExpiringSoon(LocalDocument doc) {
    final timeRemaining = getTimeRemaining(doc);
    if (timeRemaining == null) return false;
    
    return timeRemaining.inHours <= 24 && timeRemaining.inHours > 0;
  }

  /// Clean up expired files from local storage
  Future<int> cleanupExpiredFiles(String uuid) async {
    try {
      final box = await _getUserDocumentsBox(uuid);
      final now = DateTime.now();
      
      // Find expired shared files
      final expiredFiles = <int>[];
      for (int i = 0; i < box.length; i++) {
        final doc = box.getAt(i);
        if (doc != null && 
            doc.isSharedFile == true && 
            doc.expirationTime != null && 
            now.isAfter(doc.expirationTime!)) {
          expiredFiles.add(i);
        }
      }
      
      // Remove expired files (in reverse order to maintain indices)
      for (int i = expiredFiles.length - 1; i >= 0; i--) {
        await box.deleteAt(expiredFiles[i]);
      }
      
      log('Cleaned up ${expiredFiles.length} expired files');
      return expiredFiles.length;
    } catch (e) {
      log('Error cleaning up expired files: $e');
      return 0;
    }
  }

  /// Get all expired files (for display purposes)
  Future<List<LocalDocument>> getExpiredFiles(String uuid) async {
    try {
      final box = await _getUserDocumentsBox(uuid);
      final now = DateTime.now();
      
      return box.values
          .where((doc) => doc.isSharedFile == true && 
                          doc.expirationTime != null && 
                          now.isAfter(doc.expirationTime!))
          .toList();
    } catch (e) {
      log('Error getting expired files: $e');
      return [];
    }
  }

  /// Get files expiring soon
  Future<List<LocalDocument>> getExpiringSoonFiles(String uuid) async {
    try {
      final box = await _getUserDocumentsBox(uuid);
      
      return box.values
          .where((doc) => isExpiringSoon(doc))
          .toList();
    } catch (e) {
      log('Error getting expiring soon files: $e');
      return [];
    }
  }

  /// Format time remaining as human-readable string
  String formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Expired';
    }
  }

  /// Get file status for UI display
  FileAccessStatus getFileStatus(LocalDocument doc) {
    if (doc.isSharedFile != true) {
      return FileAccessStatus.permanent;
    }
    
    if (doc.expirationTime == null) {
      return FileAccessStatus.permanent;
    }
    
    final now = DateTime.now();
    if (now.isAfter(doc.expirationTime!)) {
      return FileAccessStatus.expired;
    }
    
    final timeRemaining = doc.expirationTime!.difference(now);
    if (timeRemaining.inHours <= 24) {
      return FileAccessStatus.expiringSoon;
    }
    
    return FileAccessStatus.active;
  }
}

enum FileAccessStatus {
  permanent,    // User's own files
  active,       // Shared file, still valid
  expiringSoon, // Shared file, expires within 24 hours
  expired,      // Shared file, expired
}

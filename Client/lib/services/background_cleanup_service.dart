import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/services/file_access_service.dart';

final backgroundCleanupServiceProvider = Provider<BackgroundCleanupService>((ref) {
  return BackgroundCleanupService(ref.watch(fileAccessServiceProvider));
});

class BackgroundCleanupService {
  final FileAccessService _fileAccessService;
  Timer? _cleanupTimer;
  String? _currentUuid;

  BackgroundCleanupService(this._fileAccessService);

  /// Set the current user UUID for cleanup operations
  void setCurrentUser(String uuid) {
    _currentUuid = uuid;
  }

  /// Start the background cleanup service
  void startCleanupService() {
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performCleanup();
    });
    
    // Also run cleanup immediately on start
    _performCleanup();
    
    log('Background cleanup service started');
  }

  /// Stop the background cleanup service
  void stopCleanupService() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    log('Background cleanup service stopped');
  }

  /// Perform the actual cleanup
  Future<void> _performCleanup() async {
    if (_currentUuid == null) {
      log('Background cleanup: No user UUID set, skipping cleanup');
      return;
    }
    
    try {
      final cleanedCount = await _fileAccessService.cleanupExpiredFiles(_currentUuid!);
      if (cleanedCount > 0) {
        log('Background cleanup: Removed $cleanedCount expired files');
      }
    } catch (e) {
      log('Error during background cleanup: $e');
    }
  }

  /// Manually trigger cleanup
  Future<int> triggerCleanup() async {
    if (_currentUuid == null) {
      log('Manual cleanup: No user UUID set, skipping cleanup');
      return 0;
    }
    return await _fileAccessService.cleanupExpiredFiles(_currentUuid!);
  }

  /// Get count of expired files
  Future<int> getExpiredFilesCount() async {
    if (_currentUuid == null) return 0;
    final expiredFiles = await _fileAccessService.getExpiredFiles(_currentUuid!);
    return expiredFiles.length;
  }

  /// Get count of files expiring soon
  Future<int> getExpiringSoonFilesCount() async {
    if (_currentUuid == null) return 0;
    final expiringSoonFiles = await _fileAccessService.getExpiringSoonFiles(_currentUuid!);
    return expiringSoonFiles.length;
  }
}

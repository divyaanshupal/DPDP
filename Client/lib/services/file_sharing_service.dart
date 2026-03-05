import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kyrotics/features/messaging/model/file_sharing_session.dart';

final fileSharingServiceProvider = Provider<FileSharingService>((ref) => FileSharingService());

class FileSharingService {
  static const String _baseUrl = 'https://dpdp-j99k.onrender.com';

  /// Create a new file sharing session
  Future<FileSharingSession> createSharingSession({
    required String senderUuid,
    required String receiverUuid,
    required List<String> requestedDocuments,
    required int expirationDays,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderUuid': senderUuid,
          'receiverUuid': receiverUuid,
          'requestedDocuments': requestedDocuments,
          'expirationDays': expirationDays,
          'note': note,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return FileSharingSession.fromJson(data);
      } else {
        throw Exception('Failed to create sharing session: ${response.statusCode}');
      }
    } catch (e) {
      log('Error creating sharing session: $e');
      rethrow;
    }
  }

  /// Update expiration time for a sharing session
  Future<FileSharingSession> updateExpirationTime({
    required String sessionId,
    required int expirationDays,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions/$sessionId/expiration');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'expirationDays': expirationDays,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FileSharingSession.fromJson(data);
      } else {
        throw Exception('Failed to update expiration time: ${response.statusCode}');
      }
    } catch (e) {
      log('Error updating expiration time: $e');
      rethrow;
    }
  }

  /// Accept a sharing session
  Future<FileSharingSession> acceptSharingSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions/$sessionId/accept');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'acceptedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FileSharingSession.fromJson(data);
      } else {
        throw Exception('Failed to accept sharing session: ${response.statusCode}');
      }
    } catch (e) {
      log('Error accepting sharing session: $e');
      rethrow;
    }
  }

  /// Reject a sharing session
  Future<void> rejectSharingSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions/$sessionId/reject');
      final response = await http.post(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to reject sharing session: ${response.statusCode}');
      }
    } catch (e) {
      log('Error rejecting sharing session: $e');
      rethrow;
    }
  }

  /// Get active sharing sessions for a user
  Future<List<FileSharingSession>> getActiveSessions(String uuid) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions/user/$uuid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => FileSharingSession.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get active sessions: ${response.statusCode}');
      }
    } catch (e) {
      log('Error getting active sessions: $e');
      rethrow;
    }
  }

  /// Complete a sharing session
  Future<void> completeSharingSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/sharing-sessions/$sessionId/complete');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'completedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete sharing session: ${response.statusCode}');
      }
    } catch (e) {
      log('Error completing sharing session: $e');
      rethrow;
    }
  }
}

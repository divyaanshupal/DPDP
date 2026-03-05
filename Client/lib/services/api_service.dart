import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kyrotics/models/usermodel.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/models/transaction_model.dart';

// A Riverpod Provider to give us access to this service class
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  // Use the same base URL as your signaling server
  // static const String _baseUrl = 'http://192.168.1.6:4000'; // Or your local URL
  // static const String _baseUrl = 'http://192.168.230.1:4000'; // Or your local URL
  static const String _baseUrl = 'https://dpdp-j99k.onrender.com'; // Or your local URL

  /// Fetches a user's public profile from the backend (for searching other users)
  Future<UserModel?> searchUser(String uuid) async {
    try {
      final url = Uri.parse('$_baseUrl/api/user/$uuid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        // Return null or throw a specific exception if user not found
        return null;
      }
     }catch (e) {
      // Re-throw the exception to be handled by the caller (the Notifier)
      throw Exception('Failed to connect to the server: $e');
    }
  }

  /// Fetches complete user data by UUID (for current user)
  Future<UserModel?> getUserByUuid(String uuid) async {
    try {
      final url = Uri.parse('$_baseUrl/api/user/$uuid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Syncs the local list of document names to the backend.
  Future<void> syncLocalDocumentsToBackend({
    required String uuid,
    required List<LocalDocument> localDocs,
  }) async {
    final url = Uri.parse('$_baseUrl/api/user/$uuid/documents');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'documents': localDocs
          .map((doc) => {'name': doc.name, 'fileType': doc.fileType})
          .toList(),
    });

    try {
      final response = await http.put(url, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw Exception('Failed to sync documents. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error syncing documents: $e');
    }
  }

  /// Fetches transaction history for a user
  Future<List<DocumentTransaction>> getTransactions({
    required String uuid,
    String? type, // 'sent' or 'received'
    String? status, // 'pending', 'accepted', 'rejected', 'completed', 'expired'
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/api/transactions/$uuid')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DocumentTransaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
}
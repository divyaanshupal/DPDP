import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class RegisterUser {
  static Future<Map<String, dynamic>> registerUser({
    String? name,
    String? email,
    required String phone,
  }) async {
    final url = Uri.parse(
      'https://dpdp-j99k.onrender.com/api/register',
    ); // Updated to use the correct server URL

    try {
      // Build body with only non-null fields
      final Map<String, dynamic> requestBody = {
        'phone': phone,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 12));

      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      print(response.body);
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'uuid': data['uuid']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserByEmail({
    required String email,
  }) async {
    final url = Uri.parse(
      'https://dpdp-j99k.onrender.com/api/user-by-email',
    );

    print('🔍 [getUserByEmail] Making request for email: $email');
    print('🔍 [getUserByEmail] URL: $url');

    // Retry logic with exponential backoff
    int maxRetries = 3;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        print('🔄 [getUserByEmail] Attempt ${retryCount + 1}/$maxRetries');
        
        final client = http.Client();
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Connection': 'keep-alive',
          },
          body: jsonEncode({'email': email}),
        ).timeout(
          Duration(seconds: 45), // Increased timeout for cold starts
          onTimeout: () {
            client.close();
            throw TimeoutException('Request timeout after 45 seconds');
          },
        );
        
        client.close(); // Always close the client

        print('🔍 [getUserByEmail] Response status: ${response.statusCode}');
        print('🔍 [getUserByEmail] Response body: ${response.body}');

        if (response.body.isEmpty) {
          print('❌ [getUserByEmail] Empty response from server');
          if (retryCount < maxRetries - 1) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          }
          return {'success': false, 'error': 'Empty response from server'};
        }

        final data = jsonDecode(response.body);
        print('🔍 [getUserByEmail] Parsed data: $data');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('✅ [getUserByEmail] Success! UUID: ${data['uuid']}');
          return {'success': true, 'uuid': data['uuid']};
        } else {
          print('❌ [getUserByEmail] Error response: ${data['error']}');
          return {
            'success': false,
            'error': data['error'] ?? 'User not found',
          };
        }
      } catch (e) {
        print('❌ [getUserByEmail] Attempt ${retryCount + 1} failed: $e');
        
        // Check if it's a DNS resolution or network error
        if (e.toString().contains('Failed host lookup') || 
            e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          print('🌐 [getUserByEmail] Network/DNS error detected');
          
          if (retryCount < maxRetries - 1) {
            retryCount++;
            int delaySeconds = retryCount * 3; // Longer delays for network issues: 3s, 6s, 9s
            print('⏳ [getUserByEmail] Retrying in $delaySeconds seconds...');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }
        } else {
          // For other errors, use normal retry logic
          if (retryCount < maxRetries - 1) {
            retryCount++;
            int delaySeconds = retryCount * 2;
            print('⏳ [getUserByEmail] Retrying in $delaySeconds seconds...');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          }
        }
        
        if (retryCount >= maxRetries - 1) {
          print('❌ [getUserByEmail] All attempts failed. Last error: $e');
          return {'success': false, 'error': e.toString()};
        }
      }
    }
    
    return {'success': false, 'error': 'Max retries exceeded'};
  }
}

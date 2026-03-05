import 'dart:convert';

import 'package:http/http.dart' as http;

Future<bool> logEvent({
  required String eventType,
  required String userType,
  required String uuid,
  required String metadata,
}) async {
  const String url = "http://192.168.137.235:4000/blockchain/log"; // update with your IP

  final Map<String, dynamic> body = {
    "event_type": eventType,
    "user_type": userType,
    "uuid": uuid,
    "metadata": metadata,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Event sent successfully: ${response.body}");
      return true;
    } else {
      print("❌ Failed. Status: ${response.statusCode}, Body: ${response.body}");
      return false;
    }
  } catch (e) {
    print("⚠️ Error sending event: $e");
    return false;
  }
}

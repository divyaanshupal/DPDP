import 'package:hive_flutter/hive_flutter.dart';
import 'package:kyrotics/models/usermodel.dart';

class UserStorageService {
  static const String _userBoxName = 'current_user';
  
  /// Save user data to local storage
  static Future<void> saveUser(UserModel user) async {
    try {
      final box = await Hive.openBox(_userBoxName);
      await box.put('current_user', user.toJson());
    } catch (e) {
      // Handle error silently or log it
      print('Error saving user data: $e');
    }
  }
  
  /// Get stored user data from local storage
  static Future<UserModel?> getStoredUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      final userData = box.get('current_user');
      if (userData != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
    } catch (e) {
      print('Error getting stored user data: $e');
    }
    return null;
  }
  
  /// Clear stored user data (for logout)
  static Future<void> clearStoredUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      await box.clear();
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
  
  /// Check if user data exists in storage
  static Future<bool> hasStoredUser() async {
    try {
      final box = await Hive.openBox(_userBoxName);
      return box.containsKey('current_user');
    } catch (e) {
      return false;
    }
  }
}

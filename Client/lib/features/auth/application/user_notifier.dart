import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/models/usermodel.dart';
import 'package:kyrotics/services/api_service.dart';
import 'package:kyrotics/services/registerUserFunction.dart';
import 'package:kyrotics/services/user_storage_service.dart';
import 'package:kyrotics/features/auth/application/user_state.dart';

class UserNotifier extends StateNotifier<UserState> {
  final ApiService _apiService;
  
  UserNotifier(this._apiService) : super(const UserState());

  /// Fetch complete user data by UUID from MongoDB
  Future<void> fetchUserByUuid(String uuid) async {
    // Prevent duplicate calls
    if (state.isLoading) {
      log('🔄 [UserNotifier] Already loading user data, skipping duplicate call');
      return;
    }
    
    log('🔍 [UserNotifier] Fetching user data for UUID: $uuid');
    state = state.copyWith(isLoading: true, error: null);
    
    await _fetchUserByUuidInternal(uuid);
  }

  /// Internal method to fetch user by UUID without loading state check
  Future<void> _fetchUserByUuidInternal(String uuid) async {
    try {
      final user = await _apiService.getUserByUuid(uuid);
      if (user != null) {
        log('✅ [UserNotifier] User data fetched successfully: ${user.name}');
        // Save to local storage
        await UserStorageService.saveUser(user);
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
        );
      } else {
        log('❌ [UserNotifier] User not found for UUID: $uuid');
        // If user is not found but we have partial data, keep it
        if (state.user != null && state.user!.uuid == uuid) {
          log('🔄 [UserNotifier] Keeping partial user data while waiting for MongoDB sync');
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'User not found',
            isAuthenticated: false,
          );
        }
      }
    } catch (e) {
      log('❌ [UserNotifier] Error fetching user data: $e');
      // If we have partial user data, keep it and don't show error
      if (state.user != null && state.user!.uuid == uuid) {
        log('🔄 [UserNotifier] Keeping partial user data despite fetch error');
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          isAuthenticated: false,
        );
      }
    }
  }

  /// Fetch user by email (for login flow)
  Future<void> fetchUserByEmail(String email) async {
    // Prevent duplicate calls
    if (state.isLoading) {
      log('🔄 [UserNotifier] Already loading user data, skipping duplicate call');
      return;
    }
    
    log('🔍 [UserNotifier] Fetching user by email: $email');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await RegisterUser.getUserByEmail(email: email);
      log('🔍 [UserNotifier] getUserByEmail result: $result');
      
      if (result['success']) {
        log('✅ [UserNotifier] User found by email, UUID: ${result['uuid']}');
        // Now fetch complete user data using UUID (bypass loading check)
        await _fetchUserByUuidInternal(result['uuid']);
      } else {
        log('❌ [UserNotifier] User not found by email: $email');
        log('❌ [UserNotifier] Error details: ${result['error']}');
        
        // Check if it's a network timeout error
        String errorMessage = result['error'] ?? 'User not found';
        if (errorMessage.contains('TimeoutException')) {
          errorMessage = 'Network connection timeout. Please check your internet connection and try again.';
        } else if (errorMessage.contains('SocketException') || 
                   errorMessage.contains('NetworkException') ||
                   errorMessage.contains('Failed host lookup')) {
          errorMessage = 'Network connection failed. Please check your internet connection.';
        } else if (errorMessage.contains('Max retries exceeded')) {
          errorMessage = 'Unable to connect to server after multiple attempts. Please check your internet connection.';
        }
        
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isAuthenticated: false,
        );
      }
    } catch (e) {
      log('❌ [UserNotifier] Error fetching user by email: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
        isAuthenticated: false,
      );
    }
  }

  /// Clear user data (logout)
  void clearUser() {
    log('🧹 [UserNotifier] Clearing user data');
    UserStorageService.clearStoredUser();
    state = const UserState();
  }

  /// Load user from local storage (for app startup)
  Future<void> loadStoredUser() async {
    log('📱 [UserNotifier] Loading stored user data');
    try {
      final storedUser = await UserStorageService.getStoredUser();
      if (storedUser != null) {
        log('✅ [UserNotifier] Stored user data loaded: ${storedUser.name}');
        state = state.copyWith(
          user: storedUser,
          isAuthenticated: true,
        );
      }
    } catch (e) {
      log('❌ [UserNotifier] Error loading stored user: $e');
    }
  }

  /// Update user data (for profile updates)
  void updateUser(UserModel user) {
    log('🔄 [UserNotifier] Updating user data: ${user.name}');
    state = state.copyWith(
      user: user,
      isAuthenticated: true,
      isLoading: false,
      error: null,
      signupInProgress: false, // Clear signup flag when user is set
    );
  }

  /// Set signup in progress flag
  void setSignupInProgress(bool inProgress) {
    log('🔄 [UserNotifier] Setting signup in progress: $inProgress');
    state = state.copyWith(signupInProgress: inProgress);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final currentUser = state.user;
    if (currentUser != null) {
      log('🔄 [UserNotifier] Refreshing user data');
      await fetchUserByUuid(currentUser.uuid);
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated && state.user != null;

  /// Get current user
  UserModel? get currentUser => state.user;
}

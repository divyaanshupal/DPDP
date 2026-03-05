import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/models/usermodel.dart';
import 'package:kyrotics/services/api_service.dart';
import 'package:kyrotics/features/auth/application/user_state.dart';
import 'package:kyrotics/features/auth/application/user_notifier.dart';

/// Main user provider that manages user state
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserNotifier(apiService);
});

/// Convenience provider for accessing current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(userProvider).user;
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.isAuthenticated && userState.user != null;
});

/// Convenience provider for loading state
final userLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isLoading;
});

/// Convenience provider for user error state
final userErrorProvider = Provider<String?>((ref) {
  return ref.watch(userProvider).error;
});

/// Convenience provider for user name
final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.name ?? 'User';
});

/// Convenience provider for user UUID
final userUuidProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uuid;
});

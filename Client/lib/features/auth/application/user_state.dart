import 'package:flutter/foundation.dart';
import 'package:kyrotics/models/usermodel.dart';

@immutable
class UserState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;
  final bool signupInProgress;

  const UserState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
    this.signupInProgress = false,
  });

  UserState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
    bool? signupInProgress,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      signupInProgress: signupInProgress ?? this.signupInProgress,
    );
  }

  @override
  String toString() {
    return 'UserState(isLoading: $isLoading, error: $error, user: $user, isAuthenticated: $isAuthenticated, signupInProgress: $signupInProgress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.user == user &&
        other.isAuthenticated == isAuthenticated &&
        other.signupInProgress == signupInProgress;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        error.hashCode ^
        user.hashCode ^
        isAuthenticated.hashCode ^
        signupInProgress.hashCode;
  }
}

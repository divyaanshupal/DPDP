import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/models/usermodel.dart';
import 'package:kyrotics/services/api_service.dart';

final requestTabProvider = StateNotifierProvider<RequestTabNotifier, RequestTabState>((ref) {
  return RequestTabNotifier(ref.watch(apiServiceProvider));
});

class RequestTabNotifier extends StateNotifier<RequestTabState> {
  final ApiService _apiService;
  RequestTabNotifier(this._apiService) : super(RequestTabState());

  Future<void> searchUser(String uuid) async {
    state = RequestTabState(isLoading: true); // Reset state on new search
    try {
      final user = await _apiService.searchUser(uuid);
      if (user != null) {
        state = RequestTabState(searchedUser: user);
      } else {
        state = RequestTabState(error: 'User not found.');
      }
    } catch (e) {
      state = RequestTabState(error: e.toString());
    }
  }

  void toggleDocumentSelection(String docName) {
    final currentSelection = state.selectedDocs.toSet(); // Create a mutable copy
    if (currentSelection.contains(docName)) {
      currentSelection.remove(docName);
      // Remove request type when deselecting
      final updatedRequestTypes = Map<String, String>.from(state.documentRequestTypes);
      updatedRequestTypes.remove(docName);
      state = state.copyWith(
        selectedDocs: currentSelection,
        documentRequestTypes: updatedRequestTypes,
      );
    } else {
      currentSelection.add(docName);
      // Default to 'view' when selecting
      final updatedRequestTypes = Map<String, String>.from(state.documentRequestTypes);
      updatedRequestTypes[docName] = 'view';
      state = state.copyWith(
        selectedDocs: currentSelection,
        documentRequestTypes: updatedRequestTypes,
      );
    }
  }

  // ✨ NEW: Update expiration days
  void updateExpirationDays(int days) {
    state = state.copyWith(expirationDays: days);
  }

  // ✨ NEW: Update request type for a document
  void updateDocumentRequestType(String docName, String requestType) {
    final updatedRequestTypes = Map<String, String>.from(state.documentRequestTypes);
    updatedRequestTypes[docName] = requestType;
    state = state.copyWith(documentRequestTypes: updatedRequestTypes);
  }
}

// A simple state class for our notifier
class RequestTabState {
  final bool isLoading;
  final String? error;
  final UserModel? searchedUser;
  final Set<String> selectedDocs;
  final int expirationDays; // ✨ NEW: Expiration time in days
  final Map<String, String> documentRequestTypes; // ✨ NEW: docName -> 'view' or 'download'

  RequestTabState({
    this.isLoading = false,
    this.error,
    this.searchedUser,
    this.selectedDocs = const {},
    this.expirationDays = 7, // Default to 7 days
    this.documentRequestTypes = const {}, // ✨ NEW: Default empty map
  });

  RequestTabState copyWith({
    bool? isLoading,
    String? error,
    UserModel? searchedUser,
    Set<String>? selectedDocs,
    int? expirationDays,
    Map<String, String>? documentRequestTypes,
  }) {
    return RequestTabState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchedUser: searchedUser ?? this.searchedUser,
      selectedDocs: selectedDocs ?? this.selectedDocs,
      expirationDays: expirationDays ?? this.expirationDays,
      documentRequestTypes: documentRequestTypes ?? this.documentRequestTypes,
    );
  }
}
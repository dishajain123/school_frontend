import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failure.dart';
import '../data/models/document/document_model.dart';
import '../data/repositories/document_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class DocumentState {
  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isRequesting = false,
    this.error,
  });

  final List<DocumentModel> documents;
  final bool isLoading;
  final bool isRequesting;
  final String? error;

  DocumentState copyWith({
    List<DocumentModel>? documents,
    bool? isLoading,
    bool? isRequesting,
    String? error,
    bool clearError = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isRequesting: isRequesting ?? this.isRequesting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DocumentNotifier extends AutoDisposeNotifier<DocumentState> {
  Timer? _pollTimer;
  String? _currentStudentId;

  @override
  DocumentState build() {
    ref.onDispose(_stopPolling);
    return const DocumentState();
  }

  DocumentRepository get _repo => ref.read(documentRepositoryProvider);

  // ── Load list ─────────────────────────────────────────────────────────────

  Future<void> load(String studentId) async {
    _currentStudentId = studentId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.listDocuments(studentId);
      state = state.copyWith(
        documents: result.items,
        isLoading: false,
      );
      _maybeStartPolling(studentId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: Failure.fromError(e).message,
      );
    }
  }

  // ── Request new document ──────────────────────────────────────────────────

  Future<bool> requestDocument({
    required String studentId,
    required DocumentType documentType,
    String? academicYearId,
  }) async {
    state = state.copyWith(isRequesting: true, clearError: true);
    try {
      final doc = await _repo.requestDocument(
        studentId: studentId,
        documentType: documentType,
        academicYearId: academicYearId,
      );
      // Optimistically prepend the new document at the top of the list
      state = state.copyWith(
        documents: [doc, ...state.documents],
        isRequesting: false,
      );
      // Start polling since the new doc will be PENDING/PROCESSING
      _maybeStartPolling(studentId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isRequesting: false,
        error: Failure.fromError(e).message,
      );
      return false;
    }
  }

  // ── Get download URL (not cached — presigned URLs are short-lived) ─────────

  Future<DocumentDownloadResponse?> getDownloadUrl(String documentId) async {
    try {
      return await _repo.downloadDocument(documentId);
    } catch (e) {
      state = state.copyWith(error: Failure.fromError(e).message);
      return null;
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _maybeStartPolling(String studentId) {
    final hasPollable = state.documents.any((d) => d.isPollable);
    if (hasPollable && _pollTimer == null) {
      _startPolling(studentId);
    } else if (!hasPollable) {
      _stopPolling();
    }
  }

  void _startPolling(String studentId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _pollDocuments(studentId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollDocuments(String studentId) async {
    try {
      final result = await _repo.listDocuments(studentId);
      state = state.copyWith(documents: result.items);
      final hasPollable = result.items.any((d) => d.isPollable);
      if (!hasPollable) _stopPolling();
    } catch (_) {
      // Silently ignore poll errors — UI stays unchanged
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final documentProvider =
    NotifierProvider.autoDispose<DocumentNotifier, DocumentState>(
  DocumentNotifier.new,
);

/// One-shot download URL fetch per document.
/// Not cached — presigned URLs expire quickly.
final documentDownloadProvider = FutureProvider.autoDispose
    .family<DocumentDownloadResponse, String>((ref, documentId) async {
  return ref.read(documentRepositoryProvider).downloadDocument(documentId);
});
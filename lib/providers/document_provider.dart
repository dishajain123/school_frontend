import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failure.dart';
import '../data/models/document/document_model.dart';
import '../data/repositories/document_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class DocumentState {
  const DocumentState({
    this.documents = const [],
    this.requiredDocuments = const [],
    this.requiredStatus = const [],
    this.listWorkflow = DocumentWorkflowFilter.all,
    this.isLoading = false,
    this.isRequesting = false,
    this.isUploading = false,
    this.isSavingRequirements = false,
    this.error,
  });

  final List<DocumentModel> documents;
  final List<RequiredDocumentModel> requiredDocuments;
  final List<RequiredDocumentStatusModel> requiredStatus;
  final DocumentWorkflowFilter listWorkflow;
  final bool isLoading;
  final bool isRequesting;
  final bool isUploading;
  final bool isSavingRequirements;
  final String? error;

  DocumentState copyWith({
    List<DocumentModel>? documents,
    List<RequiredDocumentModel>? requiredDocuments,
    List<RequiredDocumentStatusModel>? requiredStatus,
    DocumentWorkflowFilter? listWorkflow,
    bool? isLoading,
    bool? isRequesting,
    bool? isUploading,
    bool? isSavingRequirements,
    String? error,
    bool clearError = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      requiredStatus: requiredStatus ?? this.requiredStatus,
      listWorkflow: listWorkflow ?? this.listWorkflow,
      isLoading: isLoading ?? this.isLoading,
      isRequesting: isRequesting ?? this.isRequesting,
      isUploading: isUploading ?? this.isUploading,
      isSavingRequirements: isSavingRequirements ?? this.isSavingRequirements,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DocumentNotifier extends AutoDisposeNotifier<DocumentState> {
  Timer? _pollTimer;

  @override
  DocumentState build() {
    ref.onDispose(_stopPolling);
    return const DocumentState();
  }

  DocumentRepository get _repo => ref.read(documentRepositoryProvider);

  // ── Load list ─────────────────────────────────────────────────────────────

  Future<void> load(
    String? studentId, {
    DocumentWorkflowFilter workflow = DocumentWorkflowFilter.all,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.listDocuments(
        studentId,
        workflow: workflow,
      );
      state = state.copyWith(
        documents: result.items,
        requiredStatus: result.requiredDocuments,
        listWorkflow: workflow,
        isLoading: false,
      );
      await _loadRequirementsSilently();
      if (studentId != null && studentId.isNotEmpty) {
        _maybeStartPolling(studentId);
      } else {
        _stopPolling();
      }
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
    String? note,
  }) async {
    state = state.copyWith(isRequesting: true, clearError: true);
    try {
      final doc = await _repo.requestDocument(
        studentId: studentId,
        documentType: documentType,
        academicYearId: academicYearId,
        note: note,
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

  Future<bool> uploadDocument({
    required String studentId,
    required DocumentType documentType,
    required PlatformFile file,
    String? note,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final doc = await _repo.uploadDocument(
        studentId: studentId,
        documentType: documentType,
        file: file,
        note: note,
      );
      state = state.copyWith(
        documents: [doc, ...state.documents],
        isUploading: false,
      );
      _maybeStartPolling(studentId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
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

  Future<bool> verifyDocument({
    required String documentId,
    required bool approve,
    String? reason,
  }) async {
    DocumentModel? target;
    for (final d in state.documents) {
      if (d.id == documentId) {
        target = d;
        break;
      }
    }
    final hasFile = (target?.fileKey ?? '').trim().isNotEmpty;
    if (!hasFile) {
      state = state.copyWith(
        error: 'Uploaded file is missing for this document.',
      );
      return false;
    }

    try {
      final updated = await _repo.verifyDocument(
        documentId: documentId,
        approve: approve,
        reason: reason,
      );
      final merged = state.documents
          .map((d) => d.id == updated.id ? updated : d)
          .toList(growable: false);
      final requiredUpdated = state.requiredStatus
          .map(
            (r) => r.latestDocumentId == updated.id
                ? RequiredDocumentStatusModel(
                    documentType: r.documentType,
                    isMandatory: r.isMandatory,
                    note: r.note,
                    latestDocumentId: updated.id,
                    latestStatus: updated.status,
                    uploadedAt: updated.requestedAt,
                    reviewNote: updated.reviewNote,
                    reviewedAt: updated.reviewedAt,
                    reviewedBy: updated.reviewedBy,
                    needsReupload: updated.status == DocumentStatus.failed,
                    isCompleted: updated.status == DocumentStatus.ready,
                  )
                : r,
          )
          .toList(growable: false);
      state = state.copyWith(
        documents: merged,
        requiredStatus: requiredUpdated,
        clearError: true,
      );
      final sid = target?.studentId;
      if (sid != null && sid.isNotEmpty) {
        await refreshRequiredStatus(sid);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: Failure.fromError(e).message);
      return false;
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
      final result = await _repo.listDocuments(
        studentId,
        workflow: state.listWorkflow,
      );
      state = state.copyWith(
        documents: result.items,
        requiredStatus: result.requiredDocuments,
      );
      final hasPollable = result.items.any((d) => d.isPollable);
      if (!hasPollable) _stopPolling();
    } catch (_) {
      // Silently ignore poll errors — UI stays unchanged
    }
  }

  Future<void> _loadRequirementsSilently() async {
    try {
      final items = await _repo.listRequiredDocuments();
      state = state.copyWith(requiredDocuments: items);
    } catch (_) {
      // Keep UI non-blocking if requirements endpoint fails.
    }
  }

  Future<bool> saveRequiredDocuments(
    List<RequiredDocumentModel> items,
  ) async {
    state = state.copyWith(isSavingRequirements: true, clearError: true);
    try {
      final saved = await _repo.upsertRequiredDocuments(items);
      state = state.copyWith(
        requiredDocuments: saved,
        isSavingRequirements: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingRequirements: false,
        error: Failure.fromError(e).message,
      );
      return false;
    }
  }

  Future<void> refreshRequiredStatus(String studentId) async {
    try {
      final statuses = await _repo.listRequiredStatusForStudent(studentId);
      state = state.copyWith(requiredStatus: statuses, clearError: true);
    } catch (e) {
      state = state.copyWith(error: Failure.fromError(e).message);
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

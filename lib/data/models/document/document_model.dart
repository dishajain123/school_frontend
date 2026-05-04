import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── DocumentType ──────────────────────────────────────────────────────────────
// Mirrors backend app/utils/enums.DocumentType

enum DocumentType {
  idCard,
  bonafide,
  leavingCert,
  reportCard,
  idProof,
  addressProof,
  academicCertificate,
  transferCertificate,
  medical,
  other,
}

extension DocumentTypeX on DocumentType {
  static DocumentType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ID_CARD':
        return DocumentType.idCard;
      case 'BONAFIDE':
        return DocumentType.bonafide;
      case 'LEAVING_CERT':
        return DocumentType.leavingCert;
      case 'REPORT_CARD':
        return DocumentType.reportCard;
      case 'ID_PROOF':
        return DocumentType.idProof;
      case 'ADDRESS_PROOF':
        return DocumentType.addressProof;
      case 'ACADEMIC_CERTIFICATE':
        return DocumentType.academicCertificate;
      case 'TRANSFER_CERTIFICATE':
        return DocumentType.transferCertificate;
      case 'MEDICAL':
        return DocumentType.medical;
      case 'OTHER':
        return DocumentType.other;
      default:
        return DocumentType.bonafide;
    }
  }

  String get backendValue {
    switch (this) {
      case DocumentType.idCard:
        return 'ID_CARD';
      case DocumentType.bonafide:
        return 'BONAFIDE';
      case DocumentType.leavingCert:
        return 'LEAVING_CERT';
      case DocumentType.reportCard:
        return 'REPORT_CARD';
      case DocumentType.idProof:
        return 'ID_PROOF';
      case DocumentType.addressProof:
        return 'ADDRESS_PROOF';
      case DocumentType.academicCertificate:
        return 'ACADEMIC_CERTIFICATE';
      case DocumentType.transferCertificate:
        return 'TRANSFER_CERTIFICATE';
      case DocumentType.medical:
        return 'MEDICAL';
      case DocumentType.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.bonafide:
        return 'Bonafide Certificate';
      case DocumentType.leavingCert:
        return 'Leaving Certificate';
      case DocumentType.reportCard:
        return 'Report Card';
      case DocumentType.idProof:
        return 'ID Proof';
      case DocumentType.addressProof:
        return 'Address Proof';
      case DocumentType.academicCertificate:
        return 'Academic Certificate';
      case DocumentType.transferCertificate:
        return 'Transfer Certificate';
      case DocumentType.medical:
        return 'Medical Certificate';
      case DocumentType.other:
        return 'Other Document';
    }
  }

  String get description {
    switch (this) {
      case DocumentType.idCard:
        return 'Official student identity card';
      case DocumentType.bonafide:
        return 'Certificate confirming enrollment status';
      case DocumentType.leavingCert:
        return 'Required for school transfers';
      case DocumentType.reportCard:
        return 'Academic performance summary report';
      case DocumentType.idProof:
        return 'Government identity proof document';
      case DocumentType.addressProof:
        return 'Proof of current address';
      case DocumentType.academicCertificate:
        return 'Academic certificate issued by school';
      case DocumentType.transferCertificate:
        return 'Transfer or leaving certificate';
      case DocumentType.medical:
        return 'Medical certificate or related document';
      case DocumentType.other:
        return 'Any additional requested document';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.idCard:
        return Icons.badge_outlined;
      case DocumentType.bonafide:
        return Icons.verified_outlined;
      case DocumentType.leavingCert:
        return Icons.logout_rounded;
      case DocumentType.reportCard:
        return Icons.bar_chart_outlined;
      case DocumentType.idProof:
        return Icons.badge_outlined;
      case DocumentType.addressProof:
        return Icons.home_outlined;
      case DocumentType.academicCertificate:
        return Icons.school_outlined;
      case DocumentType.transferCertificate:
        return Icons.swap_horiz_outlined;
      case DocumentType.medical:
        return Icons.medical_information_outlined;
      case DocumentType.other:
        return Icons.description_outlined;
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.idCard:
        return AppColors.navyMedium;
      case DocumentType.bonafide:
        return AppColors.infoBlue;
      case DocumentType.leavingCert:
        return AppColors.warningAmber;
      case DocumentType.reportCard:
        return AppColors.subjectMath;
      case DocumentType.idProof:
        return AppColors.navyMedium;
      case DocumentType.addressProof:
        return AppColors.infoBlue;
      case DocumentType.academicCertificate:
        return AppColors.successGreen;
      case DocumentType.transferCertificate:
        return AppColors.warningAmber;
      case DocumentType.medical:
        return AppColors.errorRed;
      case DocumentType.other:
        return AppColors.navyDeep;
    }
  }
}

// ── DocumentStatus ────────────────────────────────────────────────────────────
// Mirrors backend app/utils/enums.DocumentStatus

enum DocumentStatus {
  pending,
  processing,
  ready,
  failed,
}

extension DocumentStatusX on DocumentStatus {
  static DocumentStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'PROCESSING':
        return DocumentStatus.processing;
      case 'READY':
      case 'VERIFIED':
        return DocumentStatus.ready;
      case 'FAILED':
      case 'REJECTED':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case DocumentStatus.pending:
        return 'PENDING';
      case DocumentStatus.processing:
        return 'PROCESSING';
      case DocumentStatus.ready:
        return 'READY';
      case DocumentStatus.failed:
        return 'FAILED';
    }
  }

  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.processing:
        return 'Pending Verification';
      case DocumentStatus.ready:
        return 'Ready';
      case DocumentStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case DocumentStatus.pending:
        return AppColors.warningAmber;
      case DocumentStatus.processing:
        return AppColors.infoBlue;
      case DocumentStatus.ready:
        return AppColors.successGreen;
      case DocumentStatus.failed:
        return AppColors.errorRed;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DocumentStatus.pending:
        return AppColors.warningLight;
      case DocumentStatus.processing:
        return AppColors.infoLight;
      case DocumentStatus.ready:
        return AppColors.successLight;
      case DocumentStatus.failed:
        return AppColors.errorLight;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentStatus.pending:
        return Icons.hourglass_empty_rounded;
      case DocumentStatus.processing:
        return Icons.sync_rounded;
      case DocumentStatus.ready:
        return Icons.check_circle_outline_rounded;
      case DocumentStatus.failed:
        return Icons.error_outline_rounded;
    }
  }

  bool get isTerminal =>
      this == DocumentStatus.ready || this == DocumentStatus.failed;

  bool get isPollable =>
      this == DocumentStatus.pending || this == DocumentStatus.processing;
}

// ── DocumentWorkflowFilter ────────────────────────────────────────────────────
// Matches backend GET /documents?status_filter= (DocumentWorkflowFilter).

enum DocumentWorkflowFilter {
  all,
  requested,
  pending,
  approved,
  rejected,
}

extension DocumentWorkflowFilterX on DocumentWorkflowFilter {
  /// Omit query param when "all" so the server default applies.
  String? get statusFilterQueryParam =>
      this == DocumentWorkflowFilter.all ? null : name;

  String get label {
    switch (this) {
      case DocumentWorkflowFilter.all:
        return 'All';
      case DocumentWorkflowFilter.requested:
        return 'Requested';
      case DocumentWorkflowFilter.pending:
        return 'Pending';
      case DocumentWorkflowFilter.approved:
        return 'Approved';
      case DocumentWorkflowFilter.rejected:
        return 'Rejected';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentWorkflowFilter.all:
        return Icons.list_rounded;
      case DocumentWorkflowFilter.requested:
        return Icons.mark_email_unread_outlined;
      case DocumentWorkflowFilter.pending:
        return Icons.sync_rounded;
      case DocumentWorkflowFilter.approved:
        return Icons.check_circle_outline_rounded;
      case DocumentWorkflowFilter.rejected:
        return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentWorkflowFilter.all:
        return AppColors.navyDeep;
      case DocumentWorkflowFilter.requested:
        return AppColors.warningAmber;
      case DocumentWorkflowFilter.pending:
        return AppColors.infoBlue;
      case DocumentWorkflowFilter.approved:
        return AppColors.successGreen;
      case DocumentWorkflowFilter.rejected:
        return AppColors.errorRed;
    }
  }
}

// ── DocumentModel ─────────────────────────────────────────────────────────────
// Mirrors DocumentResponse from app/schemas/document.py

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.studentId,
    required this.documentType,
    required this.status,
    required this.requestedAt,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.fileKey,
    this.generatedAt,
    this.reviewNote,
    this.reviewedAt,
    this.reviewedBy,
    this.studentName,
    this.studentAdmissionNumber,
    this.parentName,
  });

  final String id;
  final String studentId;
  final DocumentType documentType;
  final String? fileKey;
  final DocumentStatus status;
  final DateTime requestedAt;
  final DateTime? generatedAt;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? studentName;
  final String? studentAdmissionNumber;
  final String? parentName;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => status == DocumentStatus.ready;
  bool get hasFailed => status == DocumentStatus.failed;

  /// Polling: pending (e.g. admin request) or upload pending verification (has file).
  bool get isPollable =>
      status == DocumentStatus.pending ||
      (status == DocumentStatus.processing &&
          (fileKey != null && fileKey!.trim().isNotEmpty));

  /// PROCESSING without a file is not a valid server state; treat as pending in UI.
  DocumentStatus get displayStatus {
    if (status == DocumentStatus.processing &&
        (fileKey == null || fileKey!.trim().isEmpty)) {
      return DocumentStatus.pending;
    }
    return status;
  }

  bool get isAwaitingAdminVerification =>
      status == DocumentStatus.processing &&
      (fileKey != null && fileKey!.trim().isNotEmpty);

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      documentType: DocumentTypeX.fromString(json['document_type'] as String?),
      fileKey: json['file_key'] as String?,
      status: DocumentStatusX.fromString(json['status'] as String?),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      reviewNote: json['review_note'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      studentName: json['student_name'] as String?,
      studentAdmissionNumber: json['student_admission_number'] as String?,
      parentName: json['parent_name'] as String?,
      academicYearId: json['academic_year_id'] as String,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  DocumentModel copyWith({
    DocumentStatus? status,
    String? fileKey,
    DateTime? generatedAt,
    String? reviewNote,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? studentName,
    String? studentAdmissionNumber,
    String? parentName,
  }) {
    return DocumentModel(
      id: id,
      studentId: studentId,
      documentType: documentType,
      fileKey: fileKey ?? this.fileKey,
      status: status ?? this.status,
      requestedAt: requestedAt,
      generatedAt: generatedAt ?? this.generatedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      studentName: studentName ?? this.studentName,
      studentAdmissionNumber:
          studentAdmissionNumber ?? this.studentAdmissionNumber,
      parentName: parentName ?? this.parentName,
      academicYearId: academicYearId,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── DocumentListResponse ──────────────────────────────────────────────────────
// Mirrors DocumentListResponse from app/schemas/document.py

class DocumentListResponse {
  const DocumentListResponse({
    required this.items,
    required this.total,
    this.requiredDocuments = const [],
  });

  final List<DocumentModel> items;
  final int total;
  final List<RequiredDocumentStatusModel> requiredDocuments;

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DocumentListResponse(
      items: rawItems
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      requiredDocuments: (json['required_documents'] as List<dynamic>? ?? const [])
          .map((e) =>
              RequiredDocumentStatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── DocumentDownloadResponse ──────────────────────────────────────────────────
// Mirrors DocumentDownloadResponse from app/schemas/document.py

class DocumentDownloadResponse {
  const DocumentDownloadResponse({required this.status, this.url});

  final DocumentStatus status;
  final String? url;

  bool get hasUrl => url != null && url!.isNotEmpty;

  factory DocumentDownloadResponse.fromJson(Map<String, dynamic> json) {
    return DocumentDownloadResponse(
      status: DocumentStatusX.fromString(json['status'] as String?),
      url: json['url'] as String?,
    );
  }
}

class RequiredDocumentModel {
  const RequiredDocumentModel({
    required this.documentType,
    this.isMandatory = true,
    this.note,
    this.academicYearId,
    this.standardId,
  });

  final DocumentType documentType;
  final bool isMandatory;
  final String? note;
  final String? academicYearId;
  final String? standardId;

  factory RequiredDocumentModel.fromJson(Map<String, dynamic> json) {
    return RequiredDocumentModel(
      documentType: DocumentTypeX.fromString(json['document_type'] as String?),
      isMandatory: json['is_mandatory'] as bool? ?? true,
      note: json['note'] as String?,
      academicYearId: json['academic_year_id'] as String?,
      standardId: json['standard_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'document_type': documentType.backendValue,
        'is_mandatory': isMandatory,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        if (academicYearId != null) 'academic_year_id': academicYearId,
        if (standardId != null) 'standard_id': standardId,
      };
}

class RequiredDocumentStatusModel {
  const RequiredDocumentStatusModel({
    required this.documentType,
    required this.isMandatory,
    this.note,
    this.latestDocumentId,
    this.latestStatus,
    this.uploadedAt,
    this.reviewNote,
    this.reviewedAt,
    this.reviewedBy,
    this.needsReupload = false,
    this.isCompleted = false,
    this.academicYearId,
    this.standardId,
  });

  final DocumentType documentType;
  final bool isMandatory;
  final String? note;
  final String? latestDocumentId;
  final DocumentStatus? latestStatus;
  final DateTime? uploadedAt;
  final String? reviewNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final bool needsReupload;
  final bool isCompleted;
  final String? academicYearId;
  final String? standardId;

  factory RequiredDocumentStatusModel.fromJson(Map<String, dynamic> json) {
    return RequiredDocumentStatusModel(
      documentType: DocumentTypeX.fromString(json['document_type'] as String?),
      isMandatory: json['is_mandatory'] as bool? ?? true,
      note: json['note'] as String?,
      latestDocumentId: json['latest_document_id'] as String?,
      latestStatus: json['latest_status'] != null
          ? DocumentStatusX.fromString(json['latest_status'] as String?)
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String)
          : null,
      reviewNote: json['review_note'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      needsReupload: json['needs_reupload'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      academicYearId: json['academic_year_id'] as String?,
      standardId: json['standard_id'] as String?,
    );
  }
}

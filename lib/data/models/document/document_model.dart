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
        return 'Student ID Card';
      case DocumentType.bonafide:
        return 'Bonafide Certificate';
      case DocumentType.leavingCert:
        return 'Leaving Certificate';
      case DocumentType.reportCard:
        return 'Report Card / Result PDF';
      case DocumentType.idProof:
        return 'ID Proof';
      case DocumentType.addressProof:
        return 'Address Proof';
      case DocumentType.academicCertificate:
        return 'Academic Certificate';
      case DocumentType.transferCertificate:
        return 'School Leaving Certificate (TC/LC)';
      case DocumentType.medical:
        return 'Medical Certificate';
      case DocumentType.other:
        return 'Other (custom name)';
    }
  }

  String get description {
    switch (this) {
      case DocumentType.idCard:
        return 'Official student identity card from the school';
      case DocumentType.bonafide:
        return 'Certificate confirming enrollment and conduct';
      case DocumentType.leavingCert:
        return 'Required for school transfers';
      case DocumentType.reportCard:
        return 'Official marksheet or result PDF for an exam or term';
      case DocumentType.idProof:
        return 'Government identity proof document';
      case DocumentType.addressProof:
        return 'Proof of current address';
      case DocumentType.academicCertificate:
        return 'Academic certificate issued by school';
      case DocumentType.transferCertificate:
        return 'Transfer certificate (TC) or leaving certificate (LC) from the school';
      case DocumentType.medical:
        return 'Medical certificate or related document';
      case DocumentType.other:
        return 'Describe what you need; the school will see your exact wording';
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
  notUploaded,
  pending,
  approved,
  rejected,
  requested,
}

extension DocumentStatusX on DocumentStatus {
  static DocumentStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'NOT_UPLOADED':
        return DocumentStatus.notUploaded;
      case 'PENDING':
        return DocumentStatus.pending;
      case 'APPROVED':
        return DocumentStatus.approved;
      case 'REJECTED':
        return DocumentStatus.rejected;
      case 'REQUESTED':
        return DocumentStatus.requested;
      case 'PROCESSING':
      case 'READY':
      case 'VERIFIED':
        return DocumentStatus.approved;
      case 'FAILED':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case DocumentStatus.notUploaded:
        return 'NOT_UPLOADED';
      case DocumentStatus.pending:
        return 'PENDING';
      case DocumentStatus.approved:
        return 'APPROVED';
      case DocumentStatus.rejected:
        return 'REJECTED';
      case DocumentStatus.requested:
        return 'REQUESTED';
    }
  }

  String get label {
    switch (this) {
      case DocumentStatus.notUploaded:
        return 'Upload Required';
      case DocumentStatus.pending:
        return 'Under Review';
      case DocumentStatus.approved:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.requested:
        return 'Waiting for School';
    }
  }

  Color get color {
    switch (this) {
      case DocumentStatus.notUploaded:
        return AppColors.grey600;
      case DocumentStatus.pending:
        return AppColors.infoBlue;
      case DocumentStatus.approved:
        return AppColors.successGreen;
      case DocumentStatus.rejected:
        return AppColors.errorRed;
      case DocumentStatus.requested:
        return AppColors.warningAmber;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DocumentStatus.notUploaded:
        return AppColors.surface200;
      case DocumentStatus.pending:
        return AppColors.infoLight;
      case DocumentStatus.approved:
        return AppColors.successLight;
      case DocumentStatus.rejected:
        return AppColors.errorLight;
      case DocumentStatus.requested:
        return AppColors.warningLight;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentStatus.notUploaded:
        return Icons.upload_file_outlined;
      case DocumentStatus.pending:
        return Icons.hourglass_empty_rounded;
      case DocumentStatus.approved:
        return Icons.check_circle_outline_rounded;
      case DocumentStatus.rejected:
        return Icons.error_outline_rounded;
      case DocumentStatus.requested:
        return Icons.mark_email_unread_outlined;
    }
  }

  bool get isTerminal =>
      this == DocumentStatus.approved || this == DocumentStatus.rejected;

  /// Poll while a file is awaiting admin verification.
  bool get isPollable => this == DocumentStatus.pending;
}

// ── DocumentListStatusFilter ─────────────────────────────────────────────────
// Maps to GET /documents?status= (backend DocumentStatus).

enum DocumentListStatusFilter {
  all,
  notUploaded,
  requested,
  pending,
  approved,
  rejected,
}

extension DocumentListStatusFilterX on DocumentListStatusFilter {
  /// Omit query param when "all".
  String? get statusQueryParam =>
      this == DocumentListStatusFilter.all ? null : backendValue;

  String get backendValue {
    switch (this) {
      case DocumentListStatusFilter.all:
        return '';
      case DocumentListStatusFilter.notUploaded:
        return 'NOT_UPLOADED';
      case DocumentListStatusFilter.requested:
        return 'REQUESTED';
      case DocumentListStatusFilter.pending:
        return 'PENDING';
      case DocumentListStatusFilter.approved:
        return 'APPROVED';
      case DocumentListStatusFilter.rejected:
        return 'REJECTED';
    }
  }

  String get label {
    switch (this) {
      case DocumentListStatusFilter.all:
        return 'All';
      case DocumentListStatusFilter.notUploaded:
        return 'Not Uploaded';
      case DocumentListStatusFilter.requested:
        return 'Requested';
      case DocumentListStatusFilter.pending:
        return 'Pending';
      case DocumentListStatusFilter.approved:
        return 'Approved';
      case DocumentListStatusFilter.rejected:
        return 'Rejected';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentListStatusFilter.all:
        return Icons.list_rounded;
      case DocumentListStatusFilter.notUploaded:
        return Icons.cloud_off_outlined;
      case DocumentListStatusFilter.requested:
        return Icons.mark_email_unread_outlined;
      case DocumentListStatusFilter.pending:
        return Icons.schedule_rounded;
      case DocumentListStatusFilter.approved:
        return Icons.check_circle_outline_rounded;
      case DocumentListStatusFilter.rejected:
        return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentListStatusFilter.all:
        return AppColors.navyDeep;
      case DocumentListStatusFilter.notUploaded:
        return AppColors.grey600;
      case DocumentListStatusFilter.requested:
        return AppColors.warningAmber;
      case DocumentListStatusFilter.pending:
        return AppColors.infoBlue;
      case DocumentListStatusFilter.approved:
        return AppColors.successGreen;
      case DocumentListStatusFilter.rejected:
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
    this.fileUrl,
    this.documentTypeId,
    this.generatedAt,
    this.adminComment,
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
  final String? fileUrl;
  final String? documentTypeId;
  final DocumentStatus status;
  final DateTime requestedAt;
  final DateTime? generatedAt;
  final String? adminComment;
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

  bool get isReady => status == DocumentStatus.approved;
  bool get hasFailed => status == DocumentStatus.rejected;

  String? get rejectionReason {
    final combined = (adminComment ?? reviewNote)?.trim();
    if (combined == null || combined.isEmpty) return null;
    return combined;
  }

  /// Polling while a file is under admin review.
  bool get isPollable =>
      status == DocumentStatus.pending &&
      (fileKey != null && fileKey!.trim().isNotEmpty);

  DocumentStatus get displayStatus => status;

  bool get isAwaitingAdminVerification =>
      status == DocumentStatus.pending &&
      (fileKey != null && fileKey!.trim().isNotEmpty);

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      documentType: DocumentTypeX.fromString(json['document_type'] as String?),
      fileKey: json['file_key'] as String?,
      fileUrl: json['file_url'] as String?,
      documentTypeId: json['document_type_id'] as String?,
      status: DocumentStatusX.fromString(json['status'] as String?),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      adminComment: json['admin_comment'] as String?,
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
    String? fileUrl,
    DateTime? generatedAt,
    String? adminComment,
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
      fileUrl: fileUrl ?? this.fileUrl,
      documentTypeId: documentTypeId,
      status: status ?? this.status,
      requestedAt: requestedAt,
      generatedAt: generatedAt ?? this.generatedAt,
      adminComment: adminComment ?? this.adminComment,
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

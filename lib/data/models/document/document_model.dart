import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── DocumentType ──────────────────────────────────────────────────────────────
// Mirrors backend app/utils/enums.DocumentType

enum DocumentType {
  idCard,
  bonafide,
  leavingCert,
  reportCard,
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
        return DocumentStatus.ready;
      case 'FAILED':
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
        return 'Processing';
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
  });

  final String id;
  final String studentId;
  final DocumentType documentType;
  final String? fileKey;
  final DocumentStatus status;
  final DateTime requestedAt;
  final DateTime? generatedAt;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => status == DocumentStatus.ready;
  bool get hasFailed => status == DocumentStatus.failed;
  bool get isPollable => status.isPollable;

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
  }) {
    return DocumentModel(
      id: id,
      studentId: studentId,
      documentType: documentType,
      fileKey: fileKey ?? this.fileKey,
      status: status ?? this.status,
      requestedAt: requestedAt,
      generatedAt: generatedAt ?? this.generatedAt,
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
  const DocumentListResponse({required this.items, required this.total});

  final List<DocumentModel> items;
  final int total;

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DocumentListResponse(
      items: rawItems
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
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

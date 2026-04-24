import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── FeeCategory ───────────────────────────────────────────────────────────────
// Values must match backend app/utils/enums.FeeCategory exactly.
// fromString falls back gracefully for any unknown backend value.

enum FeeCategory {
  tuition,
  transport,
  library,
  laboratory,
  sports,
  examination,
  miscellaneous,
}

extension FeeCategoryX on FeeCategory {
  static FeeCategory fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'TUITION':
        return FeeCategory.tuition;
      case 'TRANSPORT':
        return FeeCategory.transport;
      case 'LIBRARY':
        return FeeCategory.library;
      case 'LABORATORY':
        return FeeCategory.laboratory;
      case 'SPORTS':
        return FeeCategory.sports;
      case 'EXAMINATION':
        return FeeCategory.examination;
      default:
        return FeeCategory.miscellaneous;
    }
  }

  String get backendValue {
    switch (this) {
      case FeeCategory.tuition:
        return 'TUITION';
      case FeeCategory.transport:
        return 'TRANSPORT';
      case FeeCategory.library:
        return 'LIBRARY';
      case FeeCategory.laboratory:
        return 'LABORATORY';
      case FeeCategory.sports:
        return 'SPORTS';
      case FeeCategory.examination:
        return 'EXAMINATION';
      case FeeCategory.miscellaneous:
        return 'MISCELLANEOUS';
    }
  }

  String get label {
    switch (this) {
      case FeeCategory.tuition:
        return 'Tuition';
      case FeeCategory.transport:
        return 'Transport';
      case FeeCategory.library:
        return 'Library';
      case FeeCategory.laboratory:
        return 'Laboratory';
      case FeeCategory.sports:
        return 'Sports';
      case FeeCategory.examination:
        return 'Examination';
      case FeeCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }

  IconData get icon {
    switch (this) {
      case FeeCategory.tuition:
        return Icons.school_outlined;
      case FeeCategory.transport:
        return Icons.directions_bus_outlined;
      case FeeCategory.library:
        return Icons.menu_book_outlined;
      case FeeCategory.laboratory:
        return Icons.science_outlined;
      case FeeCategory.sports:
        return Icons.sports_soccer_outlined;
      case FeeCategory.examination:
        return Icons.quiz_outlined;
      case FeeCategory.miscellaneous:
        return Icons.category_outlined;
    }
  }

  Color get color {
    switch (this) {
      case FeeCategory.tuition:
        return AppColors.navyMedium;
      case FeeCategory.transport:
        return AppColors.infoBlue;
      case FeeCategory.library:
        return AppColors.subjectHistory;
      case FeeCategory.laboratory:
        return AppColors.subjectScience;
      case FeeCategory.sports:
        return AppColors.successGreen;
      case FeeCategory.examination:
        return AppColors.subjectMath;
      case FeeCategory.miscellaneous:
        return AppColors.grey600;
    }
  }
}

// ── FeeStructureModel ─────────────────────────────────────────────────────────
// Mirrors FeeStructureResponse from app/schemas/fee.py

class FeeStructureModel {
  const FeeStructureModel({
    required this.id,
    required this.standardId,
    required this.academicYearId,
    required this.feeCategory,
    required this.amount,
    required this.dueDate,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.customFeeHead,
    this.description,
  });

  final String id;
  final String standardId;
  final String academicYearId;
  final FeeCategory feeCategory;
  final String? customFeeHead;
  final double amount;
  final DateTime dueDate;
  final String? description;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    final customFeeHead = (json['custom_fee_head'] as String?)?.trim();
    return FeeStructureModel(
      id: json['id'] as String,
      standardId: json['standard_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      feeCategory: FeeCategoryX.fromString(json['fee_category'] as String?),
      customFeeHead: (customFeeHead == null || customFeeHead.isEmpty)
          ? null
          : customFeeHead,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      description: json['description'] as String?,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get displayLabel {
    if (customFeeHead != null && customFeeHead!.trim().isNotEmpty) {
      return customFeeHead!.trim();
    }
    return feeCategory.label;
  }

  Map<String, dynamic> toJson() => {
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        'fee_category': feeCategory.backendValue,
        'amount': amount,
        'due_date':
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        if (description != null) 'description': description,
      };
}

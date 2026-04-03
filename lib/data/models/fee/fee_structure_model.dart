import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── FeeCategory ───────────────────────────────────────────────────────────────
// Values must match backend app/utils/enums.FeeCategory exactly.
// fromString falls back gracefully for any unknown backend value.

enum FeeCategory {
  tuition,
  transport,
  library,
  sports,
  exam,
  development,
  computer,
  canteen,
  hostel,
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
      case 'SPORTS':
        return FeeCategory.sports;
      case 'EXAM':
        return FeeCategory.exam;
      case 'DEVELOPMENT':
        return FeeCategory.development;
      case 'COMPUTER':
        return FeeCategory.computer;
      case 'CANTEEN':
        return FeeCategory.canteen;
      case 'HOSTEL':
        return FeeCategory.hostel;
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
      case FeeCategory.sports:
        return 'SPORTS';
      case FeeCategory.exam:
        return 'EXAM';
      case FeeCategory.development:
        return 'DEVELOPMENT';
      case FeeCategory.computer:
        return 'COMPUTER';
      case FeeCategory.canteen:
        return 'CANTEEN';
      case FeeCategory.hostel:
        return 'HOSTEL';
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
      case FeeCategory.sports:
        return 'Sports';
      case FeeCategory.exam:
        return 'Exam';
      case FeeCategory.development:
        return 'Development';
      case FeeCategory.computer:
        return 'Computer';
      case FeeCategory.canteen:
        return 'Canteen';
      case FeeCategory.hostel:
        return 'Hostel';
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
      case FeeCategory.sports:
        return Icons.sports_soccer_outlined;
      case FeeCategory.exam:
        return Icons.quiz_outlined;
      case FeeCategory.development:
        return Icons.construction_outlined;
      case FeeCategory.computer:
        return Icons.computer_outlined;
      case FeeCategory.canteen:
        return Icons.restaurant_outlined;
      case FeeCategory.hostel:
        return Icons.hotel_outlined;
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
      case FeeCategory.sports:
        return AppColors.successGreen;
      case FeeCategory.exam:
        return AppColors.subjectMath;
      case FeeCategory.development:
        return AppColors.subjectScience;
      case FeeCategory.computer:
        return AppColors.subjectPhysics;
      case FeeCategory.canteen:
        return AppColors.warningAmber;
      case FeeCategory.hostel:
        return AppColors.subjectChem;
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
    this.description,
  });

  final String id;
  final String standardId;
  final String academicYearId;
  final FeeCategory feeCategory;
  final double amount;
  final DateTime dueDate;
  final String? description;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureModel(
      id: json['id'] as String,
      standardId: json['standard_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      feeCategory: FeeCategoryX.fromString(json['fee_category'] as String?),
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      description: json['description'] as String?,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
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
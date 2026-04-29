// 🆕 NEW FILE
// lib/data/models/my_class/my_class_models.dart  [Mobile App]
// Data models for the My Class module.
// Mirrors backend schemas exactly.

class SubjectSummary {
  const SubjectSummary({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.standardId,
    required this.sectionId,
    required this.academicYearId,
    this.teacherName,
    required this.chapterCount,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String standardId;
  final String sectionId;
  final String academicYearId;
  final String? teacherName;
  final int chapterCount;

  factory SubjectSummary.fromJson(Map<String, dynamic> j) => SubjectSummary(
        subjectId: j['subject_id']?.toString() ?? '',
        subjectName: j['subject_name']?.toString() ?? '',
        subjectCode: j['subject_code']?.toString() ?? '',
        standardId: j['standard_id']?.toString() ?? '',
        sectionId: j['section_id']?.toString() ?? '',
        academicYearId: j['academic_year_id']?.toString() ?? '',
        teacherName: j['teacher_name'] as String?,
        chapterCount: (j['chapter_count'] as num?)?.toInt() ?? 0,
      );
}

class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.isLocked,
    required this.topicCount,
    required this.subjectId,
    required this.standardId,
    required this.sectionId,
    required this.academicYearId,
  });

  final String id;
  final String title;
  final String? description;
  final int orderIndex;
  final bool isLocked;
  final int topicCount;
  final String subjectId;
  final String standardId;
  final String sectionId;
  final String academicYearId;

  factory ChapterModel.fromJson(Map<String, dynamic> j) => ChapterModel(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        orderIndex: (j['order_index'] as num?)?.toInt() ?? 0,
        isLocked: j['is_locked'] as bool? ?? false,
        topicCount: (j['topic_count'] as num?)?.toInt() ?? 0,
        subjectId: j['subject_id']?.toString() ?? '',
        standardId: j['standard_id']?.toString() ?? '',
        sectionId: j['section_id']?.toString() ?? '',
        academicYearId: j['academic_year_id']?.toString() ?? '',
      );
}

class TopicModel {
  const TopicModel({
    required this.id,
    required this.chapterId,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.isLocked,
    required this.contentCount,
  });

  final String id;
  final String chapterId;
  final String title;
  final String? description;
  final int orderIndex;
  final bool isLocked;
  final int contentCount;

  factory TopicModel.fromJson(Map<String, dynamic> j) => TopicModel(
        id: j['id']?.toString() ?? '',
        chapterId: j['chapter_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        description: j['description'] as String?,
        orderIndex: (j['order_index'] as num?)?.toInt() ?? 0,
        isLocked: j['is_locked'] as bool? ?? false,
        contentCount: (j['content_count'] as num?)?.toInt() ?? 0,
      );
}

class ContentItemModel {
  const ContentItemModel({
    required this.id,
    required this.topicId,
    required this.contentType,
    this.title,
    required this.orderIndex,
    required this.isLocked,
    this.noteText,
    this.fileKey,
    this.fileName,
    this.fileMimeType,
    this.fileUrl,
    this.linkUrl,
    this.linkTitle,
    this.quizId,
  });

  final String id;
  final String topicId;
  final String contentType; // note | file | link | quiz
  final String? title;
  final int orderIndex;
  final bool isLocked;
  // note
  final String? noteText;
  // file
  final String? fileKey;
  final String? fileName;
  final String? fileMimeType;
  final String? fileUrl; // presigned URL (injected by backend)
  // link
  final String? linkUrl;
  final String? linkTitle;
  // quiz
  final String? quizId;

  factory ContentItemModel.fromJson(Map<String, dynamic> j) => ContentItemModel(
        id: j['id']?.toString() ?? '',
        topicId: j['topic_id']?.toString() ?? '',
        contentType: j['content_type']?.toString() ?? 'note',
        title: j['title'] as String?,
        orderIndex: (j['order_index'] as num?)?.toInt() ?? 0,
        isLocked: j['is_locked'] as bool? ?? false,
        noteText: j['note_text'] as String?,
        fileKey: j['file_key'] as String?,
        fileName: j['file_name'] as String?,
        fileMimeType: j['file_mime_type'] as String?,
        fileUrl: j['file_url'] as String?,
        linkUrl: j['link_url'] as String?,
        linkTitle: j['link_title'] as String?,
        quizId: j['quiz_id'] as String?,
      );
}

class QuizModel {
  const QuizModel({
    required this.id,
    required this.topicId,
    required this.title,
    this.instructions,
    required this.totalMarks,
    this.durationMinutes,
    required this.isLocked,
    required this.questionCount,
    this.questions = const [],
  });

  final String id;
  final String topicId;
  final String title;
  final String? instructions;
  final int totalMarks;
  final int? durationMinutes;
  final bool isLocked;
  final int questionCount;
  final List<QuestionModel> questions;

  factory QuizModel.fromJson(Map<String, dynamic> j) => QuizModel(
        id: j['id']?.toString() ?? '',
        topicId: j['topic_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        instructions: j['instructions'] as String?,
        totalMarks: (j['total_marks'] as num?)?.toInt() ?? 0,
        durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
        isLocked: j['is_locked'] as bool? ?? false,
        questionCount: (j['question_count'] as num?)?.toInt() ?? 0,
        questions: (j['questions'] as List?)
                ?.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.marks,
    required this.orderIndex,
    // correct_answer is NOT included (hidden from students)
  });

  final String id;
  final String quizId;
  final String questionText;
  final String questionType; // mcq | true_false | short_answer
  final List<String>? options;
  final int marks;
  final int orderIndex;

  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
        id: j['id']?.toString() ?? '',
        quizId: j['quiz_id']?.toString() ?? '',
        questionText: j['question_text']?.toString() ?? '',
        questionType: j['question_type']?.toString() ?? 'mcq',
        options: (j['options_json'] as List?)?.map((e) => e.toString()).toList(),
        marks: (j['marks'] as num?)?.toInt() ?? 1,
        orderIndex: (j['order_index'] as num?)?.toInt() ?? 0,
      );
}

class AttemptResultModel {
  const AttemptResultModel({
    required this.id,
    required this.quizId,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.isCompleted,
    required this.questionsWithResults,
    required this.submittedAt,
  });

  final String id;
  final String quizId;
  final int score;
  final int totalMarks;
  final double percentage;
  final bool isCompleted;
  final List<Map<String, dynamic>> questionsWithResults;
  final String submittedAt;

  factory AttemptResultModel.fromJson(Map<String, dynamic> j) => AttemptResultModel(
        id: j['id']?.toString() ?? '',
        quizId: j['quiz_id']?.toString() ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        totalMarks: (j['total_marks'] as num?)?.toInt() ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0.0,
        isCompleted: j['is_completed'] as bool? ?? false,
        questionsWithResults:
            (j['questions_with_results'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        submittedAt: j['created_at']?.toString() ?? '',
      );
}

class AttemptSummary {
  const AttemptSummary({
    required this.items,
    required this.total,
    this.bestScore,
    this.latestAttemptId,
  });

  final List<AttemptResultModel> items;
  final int total;
  final int? bestScore;
  final String? latestAttemptId;

  factory AttemptSummary.fromJson(Map<String, dynamic> j) => AttemptSummary(
        items: (j['items'] as List?)
                ?.map((e) => AttemptResultModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        total: (j['total'] as num?)?.toInt() ?? 0,
        bestScore: (j['best_score'] as num?)?.toInt(),
        latestAttemptId: j['latest_attempt_id'] as String?,
      );
}
// 🆕 NEW FILE
// lib/providers/my_class_provider.dart  [Mobile App]
// Riverpod providers for the My Class module.
// Pattern matches existing providers (e.g. lib/providers/enrollment_provider.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../data/models/my_class/my_class_models.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class MyClassRepository {
  MyClassRepository(this._dio);
  final Dio _dio;

  // Subjects
  Future<List<SubjectSummary>> getSubjects({
    required String standardId,
    required String sectionId,
    required String academicYearId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/subjects',
      queryParameters: {
        'standard_id': standardId,
        'section_id': sectionId,
        'academic_year_id': academicYearId,
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    final items = (data?['items'] as List?) ?? [];
    return items
        .map((e) => SubjectSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Chapters
  Future<List<ChapterModel>> getChapters({
    required String subjectId,
    required String standardId,
    required String sectionId,
    required String academicYearId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/chapters',
      queryParameters: {
        'subject_id': subjectId,
        'standard_id': standardId,
        'section_id': sectionId,
        'academic_year_id': academicYearId,
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    final items = (data?['items'] as List?) ?? [];
    return items
        .map((e) => ChapterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Topics
  Future<List<TopicModel>> getTopics({
    required String chapterId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/topics',
      queryParameters: {
        'chapter_id': chapterId,
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    final items = (data?['items'] as List?) ?? [];
    return items
        .map((e) => TopicModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Content
  Future<List<ContentItemModel>> getContent({
    required String topicId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/content',
      queryParameters: {
        'topic_id': topicId,
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    final items = (data?['items'] as List?) ?? [];
    return items
        .map((e) => ContentItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Quiz (public — no answers)
  Future<QuizModel> getQuiz({
    required String quizId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/quizzes/$quizId',
      queryParameters: {
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return QuizModel.fromJson(data as Map<String, dynamic>);
  }

  // Submit attempt
  Future<AttemptResultModel> submitAttempt({
    required String quizId,
    required Map<String, String> answers,
    String? childId,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/quizzes/$quizId/attempt',
      queryParameters: {
        if (childId != null) 'child_id': childId,
      },
      data: {
        'quiz_id': quizId,
        'answers_json': answers,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return AttemptResultModel.fromJson(data as Map<String, dynamic>);
  }

  // My attempts
  Future<AttemptSummary> getMyAttempts({
    required String quizId,
    String? childId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/quizzes/$quizId/attempts/mine',
      queryParameters: {
        if (childId != null) 'child_id': childId,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return AttemptSummary.fromJson(data as Map<String, dynamic>);
  }

  // ── Teacher: create chapter ───────────────────────────────────────────────
  Future<ChapterModel> createChapter({
    required String subjectId,
    required String standardId,
    required String sectionId,
    required String academicYearId,
    required String title,
    String? description,
    int orderIndex = 0,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/chapters',
      data: {
        'subject_id': subjectId,
        'standard_id': standardId,
        'section_id': sectionId,
        'academic_year_id': academicYearId,
        'title': title,
        if (description != null) 'description': description,
        'order_index': orderIndex,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return ChapterModel.fromJson(data as Map<String, dynamic>);
  }

  // Teacher: create topic
  Future<TopicModel> createTopic({
    required String chapterId,
    required String title,
    String? description,
    int orderIndex = 0,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/topics',
      data: {
        'chapter_id': chapterId,
        'title': title,
        if (description != null) 'description': description,
        'order_index': orderIndex,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return TopicModel.fromJson(data as Map<String, dynamic>);
  }

  // Teacher: add content
  Future<ContentItemModel> addContent({
    required String topicId,
    required String contentType,
    required String academicYearId,
    required String standardId,
    required String sectionId,
    required String subjectId,
    String? title,
    String? noteText,
    String? fileKey,
    String? fileName,
    String? fileMimeType,
    String? linkUrl,
    String? linkTitle,
    String? quizId,
    int orderIndex = 0,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/content',
      data: {
        'topic_id': topicId,
        'content_type': contentType,
        'academic_year_id': academicYearId,
        'standard_id': standardId,
        'section_id': sectionId,
        'subject_id': subjectId,
        if (title != null) 'title': title,
        if (noteText != null) 'note_text': noteText,
        if (fileKey != null) 'file_key': fileKey,
        if (fileName != null) 'file_name': fileName,
        if (fileMimeType != null) 'file_mime_type': fileMimeType,
        if (linkUrl != null) 'link_url': linkUrl,
        if (linkTitle != null) 'link_title': linkTitle,
        if (quizId != null) 'quiz_id': quizId,
        'order_index': orderIndex,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return ContentItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, String>> uploadMyClassFile({
    required String standardId,
    required String sectionId,
    required String subjectId,
    required String academicYearId,
    required MultipartFile file,
  }) async {
    final form = FormData.fromMap({
      'standard_id': standardId,
      'section_id': sectionId,
      'subject_id': subjectId,
      'academic_year_id': academicYearId,
      'file': file,
    });
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/upload-file',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = resp.data?['data'] ?? resp.data ?? const {};
    return {
      'file_key': data['file_key']?.toString() ?? '',
      'file_name': data['file_name']?.toString() ?? '',
      'file_mime_type': data['file_mime_type']?.toString() ?? 'application/octet-stream',
    };
  }

  Future<QuizModel> createQuiz({
    required String topicId,
    required String title,
    String? instructions,
    int? durationMinutes,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/my-class/quizzes',
      data: {
        'topic_id': topicId,
        'title': title,
        if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      },
    );
    final data = resp.data?['data'] ?? resp.data;
    return QuizModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> addQuestion({
    required String quizId,
    required String questionText,
    required String questionType,
    required String correctAnswer,
    List<String>? options,
    int marks = 1,
    int orderIndex = 0,
    String? explanation,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/my-class/questions',
      data: {
        'quiz_id': quizId,
        'question_text': questionText,
        'question_type': questionType,
        if (options != null && options.isNotEmpty) 'options_json': options,
        'correct_answer': correctAnswer,
        'marks': marks,
        'order_index': orderIndex,
        if (explanation != null && explanation.isNotEmpty) 'explanation': explanation,
      },
    );
  }

  Future<AttemptSummary> getQuizAttempts({
    required String quizId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/my-class/quizzes/$quizId/attempts',
    );
    final data = resp.data?['data'] ?? resp.data;
    return AttemptSummary.fromJson(data as Map<String, dynamic>);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final myClassRepositoryProvider = Provider<MyClassRepository>((ref) {
  return MyClassRepository(ref.watch(dioClientProvider));
});

// Param types
typedef _SubjectParams = ({
  String standardId,
  String sectionId,
  String academicYearId,
  String? childId,
});

typedef _ChapterParams = ({
  String subjectId,
  String standardId,
  String sectionId,
  String academicYearId,
  String? childId,
});

typedef _TopicParams = ({
  String chapterId,
  String? childId,
});

typedef _ContentParams = ({
  String topicId,
  String? childId,
});

typedef _QuizParams = ({
  String quizId,
  String? childId,
});

final myClassSubjectsProvider =
    FutureProvider.family<List<SubjectSummary>, _SubjectParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getSubjects(
        standardId: p.standardId,
        sectionId: p.sectionId,
        academicYearId: p.academicYearId,
        childId: p.childId,
      );
});

final myClassChaptersProvider =
    FutureProvider.family<List<ChapterModel>, _ChapterParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getChapters(
        subjectId: p.subjectId,
        standardId: p.standardId,
        sectionId: p.sectionId,
        academicYearId: p.academicYearId,
        childId: p.childId,
      );
});

final myClassTopicsProvider =
    FutureProvider.family<List<TopicModel>, _TopicParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getTopics(
        chapterId: p.chapterId,
        childId: p.childId,
      );
});

final myClassContentProvider =
    FutureProvider.family<List<ContentItemModel>, _ContentParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getContent(
        topicId: p.topicId,
        childId: p.childId,
      );
});

final myClassQuizProvider =
    FutureProvider.family<QuizModel, _QuizParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getQuiz(
        quizId: p.quizId,
        childId: p.childId,
      );
});

final myClassAttemptsProvider =
    FutureProvider.family<AttemptSummary, _QuizParams>((ref, p) {
  return ref.watch(myClassRepositoryProvider).getMyAttempts(
        quizId: p.quizId,
        childId: p.childId,
      );
});

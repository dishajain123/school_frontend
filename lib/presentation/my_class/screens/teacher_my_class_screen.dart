// 🆕 NEW FILE
// lib/presentation/my_class/screens/teacher_my_class_screen.dart  [Mobile App]
// My Class — Teacher Content Management (decision #5: separate route).
//
// Entry point: TeacherScheduleScreen → "Manage Class Content" button
// Navigation: context.push('/teacher/my-class', extra: assignment)
//
// Step flow:
//   1. Select academic year / class / section / subject  (from teacher's assignments)
//   2. View / create chapters
//   3. View / create topics
//   4. Add content (note / file / link / quiz)
//
// APIs used:
//   GET  /teacher-assignments/mine?academic_year_id=
//   GET  /my-class/chapters
//   POST /my-class/chapters
//   GET  /my-class/topics
//   POST /my-class/topics
//   GET  /my-class/content
//   POST /my-class/content
//   POST /my-class/quizzes
//   POST /my-class/questions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/my_class/my_class_models.dart';
import '../../../providers/my_class_provider.dart';
import '../../common/widgets/app_app_bar.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────

enum _Step { selectAssignment, chapters, topics, content }

// ── Assignment model (from teacher-assignments/mine) ──────────────────────────

class _AssignmentContext {
  const _AssignmentContext({
    required this.id,
    required this.standardId,
    required this.standardName,
    required this.section,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.academicYearId,
    required this.academicYearName,
  });

  final String id;
  final String standardId;
  final String standardName;
  final String section;
  final String sectionId;
  final String subjectId;
  final String subjectName;
  final String academicYearId;
  final String academicYearName;

  String get label =>
      '$subjectName — ${standardName} ${section} ($academicYearName)';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherMyClassScreen extends ConsumerStatefulWidget {
  const TeacherMyClassScreen({super.key});

  @override
  ConsumerState<TeacherMyClassScreen> createState() =>
      _TeacherMyClassScreenState();
}

class _TeacherMyClassScreenState extends ConsumerState<TeacherMyClassScreen> {
  _Step _step = _Step.selectAssignment;
  _AssignmentContext? _selected;
  ChapterModel? _selectedChapter;
  TopicModel? _selectedTopic;

  List<_AssignmentContext> _assignments = [];
  bool _loadingAssignments = true;

  // Data lists
  List<ChapterModel> _chapters = [];
  List<TopicModel> _topics = [];
  List<ContentItemModel> _contents = [];
  bool _loading = false;
  String? _error;

  int get _selectedChapterNumber {
    if (_selectedChapter == null) return 1;
    final idx = _chapters.indexWhere((c) => c.id == _selectedChapter!.id);
    return idx >= 0 ? idx + 1 : 1;
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(
        ApiConstants.teacherAssignmentsMine,
      );
      final raw = resp.data?['data'] ?? resp.data;
      final items = (raw?['items'] as List?) ?? [];
      final parsed = <_AssignmentContext>[];
      for (final e in items) {
        final stdId = e['standard']?['id']?.toString() ?? '';
        final subId = e['subject']?['id']?.toString() ?? '';
        final yearId = e['academic_year']?['id']?.toString() ?? '';
        // section_id is not returned by teacher-assignments — we need to resolve
        // it via the sections endpoint. We store section name here and resolve
        // section_id lazily when needed.
        parsed.add(_AssignmentContext(
          id: e['id']?.toString() ?? '',
          standardId: stdId,
          standardName: e['standard']?['name']?.toString() ?? '',
          section: e['section']?.toString() ?? '',
          sectionId: e['section_id']?.toString() ?? '',
          subjectId: subId,
          subjectName: e['subject']?['name']?.toString() ?? '',
          academicYearId: yearId,
          academicYearName: e['academic_year']?['name']?.toString() ?? '',
        ));
      }
      if (mounted) {
        setState(() {
          _assignments = parsed;
          _loadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAssignments = false);
    }
  }

  String _normalizeSectionName(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.startsWith('SECTION ')) {
      return trimmed.substring('SECTION '.length).trim();
    }
    return trimmed;
  }

  /// Resolve section UUID from masters/sections for the selected assignment.
  Future<String> _resolveSectionId(_AssignmentContext ctx) async {
    if (ctx.sectionId.trim().isNotEmpty) {
      return ctx.sectionId.trim();
    }
    final dio = ref.read(dioClientProvider);
    final resp = await dio.get<Map<String, dynamic>>(
      ApiConstants.mastersSections,
      queryParameters: {
        'standard_id': ctx.standardId,
        'academic_year_id': ctx.academicYearId,
      },
    );
    final raw = resp.data?['data'] ?? resp.data;
    final items = (raw?['items'] as List?) ?? (raw is List ? raw : []);
    final wanted = _normalizeSectionName(ctx.section);
    for (final item in items) {
      final itemName = _normalizeSectionName(item['name']?.toString() ?? '');
      if (itemName == wanted) {
        return item['id']?.toString() ?? '';
      }
    }
    throw Exception(
        'Section not found for ${ctx.standardName} (${ctx.section})');
  }

  Future<void> _selectAssignment(_AssignmentContext ctx) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sectionId = await _resolveSectionId(ctx);
      final resolvedCtx = _AssignmentContext(
        id: ctx.id,
        standardId: ctx.standardId,
        standardName: ctx.standardName,
        section: ctx.section,
        sectionId: sectionId,
        subjectId: ctx.subjectId,
        subjectName: ctx.subjectName,
        academicYearId: ctx.academicYearId,
        academicYearName: ctx.academicYearName,
      );
      final repo = ref.read(myClassRepositoryProvider);
      final chapters = await repo.getChapters(
        subjectId: resolvedCtx.subjectId,
        standardId: resolvedCtx.standardId,
        sectionId: resolvedCtx.sectionId,
        academicYearId: resolvedCtx.academicYearId,
      );
      setState(() {
        _selected = resolvedCtx;
        _chapters = chapters;
        _step = _Step.chapters;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectChapter(ChapterModel chapter) async {
    setState(() => _loading = true);
    try {
      final topics = await ref
          .read(myClassRepositoryProvider)
          .getTopics(chapterId: chapter.id);
      setState(() {
        _selectedChapter = chapter;
        _topics = topics;
        _step = _Step.topics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectTopic(TopicModel topic) async {
    setState(() => _loading = true);
    try {
      final content = await ref
          .read(myClassRepositoryProvider)
          .getContent(topicId: topic.id);
      setState(() {
        _selectedTopic = topic;
        _contents = content;
        _step = _Step.content;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _goBack() {
    if (_step == _Step.selectAssignment) {
      if (_error != null) {
        setState(() => _error = null);
        return;
      }
      context.go(RouteNames.dashboard);
      return;
    }
    setState(() {
      _error = null;
      switch (_step) {
        case _Step.chapters:
          _step = _Step.selectAssignment;
          _selected = null;
          break;
        case _Step.topics:
          _step = _Step.chapters;
          _selectedChapter = null;
          break;
        case _Step.content:
          _step = _Step.topics;
          _selectedTopic = null;
          break;
        case _Step.selectAssignment:
          break;
      }
    });
  }

  Future<void> _showCreateChapterDialog() async {
    final title =
        await _showInputDialog(context, 'New Chapter', 'Chapter title');
    if (title == null || title.isEmpty) return;
    setState(() => _loading = true);
    try {
      final chapter = await ref.read(myClassRepositoryProvider).createChapter(
            subjectId: _selected!.subjectId,
            standardId: _selected!.standardId,
            sectionId: _selected!.sectionId,
            academicYearId: _selected!.academicYearId,
            title: title,
            orderIndex: _chapters.length,
          );
      setState(() {
        _chapters = [..._chapters, chapter];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showCreateTopicDialog() async {
    final title = await _showInputDialog(context, 'New Topic', 'Topic title');
    if (title == null || title.isEmpty) return;
    setState(() => _loading = true);
    try {
      final topic = await ref.read(myClassRepositoryProvider).createTopic(
            chapterId: _selectedChapter!.id,
            title: title,
            orderIndex: _topics.length,
          );
      setState(() {
        _topics = [..._topics, topic];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showAddContentSheet() async {
    final ctx = _selected!;
    final topicId = _selectedTopic!.id;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddContentSheet(
        topicId: topicId,
        academicYearId: ctx.academicYearId,
        standardId: ctx.standardId,
        sectionId: ctx.sectionId,
        subjectId: ctx.subjectId,
        orderIndex: _contents.length,
        onAdded: (item) {
          setState(() => _contents = [..._contents, item]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(
          title: _stepTitle,
          showBack: true,
          onBackPressed: _goBack,
          actions: [
            if (_step == _Step.chapters)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New Chapter',
                onPressed: _loading ? null : _showCreateChapterDialog,
              ),
            if (_step == _Step.topics)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New Topic',
                onPressed: _loading ? null : _showCreateTopicDialog,
              ),
            if (_step == _Step.content)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Content',
                onPressed: _loading ? null : _showAddContentSheet,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case _Step.selectAssignment:
        return 'Select Class';
      case _Step.chapters:
        return _selected?.subjectName ?? 'Chapters';
      case _Step.topics:
        return _selectedChapter?.title ?? 'Topics';
      case _Step.content:
        return _selectedTopic?.title ?? 'Content';
    }
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Dismiss')),
          ],
        ),
      );
    }

    switch (_step) {
      case _Step.selectAssignment:
        return _SelectAssignmentView(
          assignments: _assignments,
          loading: _loadingAssignments,
          onSelect: _selectAssignment,
        );
      case _Step.chapters:
        return _ListViewWithBreadcrumb<ChapterModel>(
          breadcrumb: _selected!.label,
          items: _chapters,
          emptyText: 'No chapters yet. Tap + to create one.',
          labelBuilder: (c) => c.title,
          subtitleBuilder: (c) => '${c.topicCount} topics',
          itemPrefixBuilder: (index) => '${index + 1}',
          onTap: (c) => _selectChapter(c),
        );
      case _Step.topics:
        return _ListViewWithBreadcrumb<TopicModel>(
          breadcrumb: '${_selected!.subjectName} › ${_selectedChapter!.title}',
          items: _topics,
          emptyText: 'No topics yet. Tap + to create one.',
          labelBuilder: (t) => t.title,
          subtitleBuilder: (t) => '${t.contentCount} items',
          itemPrefixBuilder: (index) => '$_selectedChapterNumber.${index + 1}',
          onTap: (t) => _selectTopic(t),
        );
      case _Step.content:
        return _ContentListView(
          breadcrumb: '${_selectedChapter!.title} › ${_selectedTopic!.title}',
          contents: _contents,
        );
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SelectAssignmentView extends StatelessWidget {
  const _SelectAssignmentView({
    required this.assignments,
    required this.loading,
    required this.onSelect,
  });
  final List<_AssignmentContext> assignments;
  final bool loading;
  final void Function(_AssignmentContext) onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (assignments.isEmpty) {
      return Center(
          child: Text('No class assignments found.',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.grey500)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = assignments[i];
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(a.subjectName,
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${a.standardName} · Section ${a.section} · ${a.academicYearName}',
              style: AppTypography.caption.copyWith(color: AppColors.grey500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(a),
          ),
        );
      },
    );
  }
}

class _ListViewWithBreadcrumb<T> extends StatelessWidget {
  const _ListViewWithBreadcrumb({
    required this.breadcrumb,
    required this.items,
    required this.emptyText,
    required this.labelBuilder,
    required this.subtitleBuilder,
    this.itemPrefixBuilder,
    required this.onTap,
  });
  final String breadcrumb;
  final List<T> items;
  final String emptyText;
  final String Function(T) labelBuilder;
  final String Function(T) subtitleBuilder;
  final String Function(int index)? itemPrefixBuilder;
  final void Function(T) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface100,
          child: Text(breadcrumb,
              style: AppTypography.caption.copyWith(color: AppColors.grey600)),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(emptyText,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final prefix = itemPrefixBuilder?.call(i);
                    final titleText = labelBuilder(item);
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                            prefix == null ? titleText : '$prefix  $titleText',
                            style: AppTypography.labelLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(subtitleBuilder(item),
                            style: AppTypography.caption
                                .copyWith(color: AppColors.grey500)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onTap(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ContentListView extends ConsumerWidget {
  const _ContentListView({required this.breadcrumb, required this.contents});
  final String breadcrumb;
  final List<ContentItemModel> contents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface100,
          child: Text(breadcrumb,
              style: AppTypography.caption.copyWith(color: AppColors.grey600)),
        ),
        Expanded(
          child: contents.isEmpty
              ? Center(
                  child: Text('No content yet. Tap + to add.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contents.length,
                  itemBuilder: (_, i) {
                    final item = contents[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(_iconFor(item.contentType),
                            color: AppColors.navyMedium),
                        title: Text(
                          item.title ??
                              item.linkTitle ??
                              item.fileName ??
                              item.contentType,
                          style: AppTypography.labelMedium,
                        ),
                        subtitle: Text(item.contentType.toUpperCase(),
                            style: AppTypography.caption
                                .copyWith(color: AppColors.grey500)),
                        trailing:
                            item.contentType == 'quiz' && item.quizId != null
                                ? const Icon(Icons.insights_outlined)
                                : null,
                        onTap: item.contentType == 'quiz' && item.quizId != null
                            ? () async {
                                final attempts = await ref
                                    .read(myClassRepositoryProvider)
                                    .getQuizAttempts(quizId: item.quizId!);
                                if (!context.mounted) return;
                                showModalBottomSheet<void>(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (_) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Quiz Analytics',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                            'Total Attempts: ${attempts.total}'),
                                        Text(
                                            'Best Score: ${attempts.bestScore ?? 0}'),
                                        if (attempts.items.isNotEmpty)
                                          Text(
                                            'Latest Score: ${attempts.items.first.score}/${attempts.items.first.totalMarks}',
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'file':
        return Icons.picture_as_pdf_outlined;
      case 'link':
        return Icons.link_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      default:
        return Icons.notes_outlined;
    }
  }
}

// ── Add Content Bottom Sheet ──────────────────────────────────────────────────

class _AddContentSheet extends ConsumerStatefulWidget {
  const _AddContentSheet({
    required this.topicId,
    required this.academicYearId,
    required this.standardId,
    required this.sectionId,
    required this.subjectId,
    required this.orderIndex,
    required this.onAdded,
  });

  final String topicId;
  final String academicYearId;
  final String standardId;
  final String sectionId;
  final String subjectId;
  final int orderIndex;
  final void Function(ContentItemModel) onAdded;

  @override
  ConsumerState<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends ConsumerState<_AddContentSheet> {
  String _type = 'note';
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<_LinkDraftControllers> _linkDrafts = [];
  final _quizTitleCtrl = TextEditingController();
  final _quizDurationCtrl = TextEditingController();
  final List<_QuestionDraft> _questions = [];
  PlatformFile? _pickedFile;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _linkDrafts.add(_LinkDraftControllers());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    for (final draft in _linkDrafts) {
      draft.dispose();
    }
    _quizTitleCtrl.dispose();
    _quizDurationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedFile = res.files.first);
    }
  }

  Future<void> _addQuestionDialog() async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final o1 = TextEditingController();
    final o2 = TextEditingController();
    final o3 = TextEditingController();
    final o4 = TextEditingController();
    final marksCtrl = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: qCtrl,
                  decoration: const InputDecoration(labelText: 'Question')),
              TextField(
                  controller: o1,
                  decoration: const InputDecoration(labelText: 'Option 1')),
              TextField(
                  controller: o2,
                  decoration: const InputDecoration(labelText: 'Option 2')),
              TextField(
                  controller: o3,
                  decoration: const InputDecoration(labelText: 'Option 3')),
              TextField(
                  controller: o4,
                  decoration: const InputDecoration(labelText: 'Option 4')),
              TextField(
                  controller: aCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Correct Answer')),
              TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marks')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final question = qCtrl.text.trim();
              final answer = aCtrl.text.trim();
              if (question.isEmpty || answer.isEmpty) return;
              final opts = [
                o1.text.trim(),
                o2.text.trim(),
                o3.text.trim(),
                o4.text.trim()
              ].where((e) => e.isNotEmpty).toList();
              setState(() {
                _questions.add(
                  _QuestionDraft(
                    questionText: question,
                    correctAnswer: answer,
                    options: opts,
                    marks: int.tryParse(marksCtrl.text.trim()) ?? 1,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    qCtrl.dispose();
    aCtrl.dispose();
    o1.dispose();
    o2.dispose();
    o3.dispose();
    o4.dispose();
    marksCtrl.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? fileKey;
      String? fileName;
      String? fileMimeType;
      String? quizId;
      final createdItems = <ContentItemModel>[];

      if (_type == 'file') {
        if (_pickedFile == null ||
            (_pickedFile!.bytes == null && _pickedFile!.path == null)) {
          throw Exception('Please pick a file');
        }
        final multipart = _pickedFile!.bytes != null
            ? MultipartFile.fromBytes(
                _pickedFile!.bytes!,
                filename: _pickedFile!.name,
              )
            : await MultipartFile.fromFile(_pickedFile!.path!,
                filename: _pickedFile!.name);

        final uploaded =
            await ref.read(myClassRepositoryProvider).uploadMyClassFile(
                  standardId: widget.standardId,
                  sectionId: widget.sectionId,
                  subjectId: widget.subjectId,
                  academicYearId: widget.academicYearId,
                  file: multipart,
                );
        fileKey = uploaded['file_key'];
        fileName = uploaded['file_name'];
        fileMimeType = uploaded['file_mime_type'];
      }

      if (_type == 'quiz') {
        if (_quizTitleCtrl.text.trim().isEmpty) {
          throw Exception('Quiz title is required');
        }
        final quiz = await ref.read(myClassRepositoryProvider).createQuiz(
              topicId: widget.topicId,
              title: _quizTitleCtrl.text.trim(),
              durationMinutes: int.tryParse(_quizDurationCtrl.text.trim()),
            );
        quizId = quiz.id;
        for (int i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          await ref.read(myClassRepositoryProvider).addQuestion(
                quizId: quizId,
                questionText: q.questionText,
                questionType: 'mcq',
                correctAnswer: q.correctAnswer,
                options: q.options,
                marks: q.marks,
                orderIndex: i,
              );
        }
      }

      if (_type == 'link') {
        final links = _linkDrafts
            .map((d) => (
                  url: d.urlCtrl.text.trim(),
                  title: d.titleCtrl.text.trim(),
                ))
            .where((l) => l.url.isNotEmpty)
            .toList();
        if (links.isEmpty) {
          throw Exception('Please add at least one link');
        }
        var nextOrder = widget.orderIndex;
        for (final link in links) {
          final item = await ref.read(myClassRepositoryProvider).addContent(
                topicId: widget.topicId,
                contentType: 'link',
                academicYearId: widget.academicYearId,
                standardId: widget.standardId,
                sectionId: widget.sectionId,
                subjectId: widget.subjectId,
                title: _titleCtrl.text.trim().isEmpty
                    ? (link.title.isEmpty ? null : link.title)
                    : _titleCtrl.text.trim(),
                linkUrl: link.url,
                linkTitle: link.title.isEmpty ? null : link.title,
                orderIndex: nextOrder++,
              );
          createdItems.add(item);
        }
      } else {
        final item = await ref.read(myClassRepositoryProvider).addContent(
              topicId: widget.topicId,
              contentType: _type,
              academicYearId: widget.academicYearId,
              standardId: widget.standardId,
              sectionId: widget.sectionId,
              subjectId: widget.subjectId,
              title: _titleCtrl.text.trim().isEmpty
                  ? null
                  : _titleCtrl.text.trim(),
              noteText: _type == 'note' ? _noteCtrl.text : null,
              fileKey: _type == 'file' ? fileKey : null,
              fileName: _type == 'file' ? fileName : null,
              fileMimeType: _type == 'file' ? fileMimeType : null,
              quizId: _type == 'quiz' ? quizId : null,
              orderIndex: widget.orderIndex,
            );
        createdItems.add(item);
      }
      for (final item in createdItems) {
        widget.onAdded(item);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Content',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'note', label: Text('Note')),
                ButtonSegment(value: 'file', label: Text('File')),
                ButtonSegment(value: 'link', label: Text('Link')),
                ButtonSegment(value: 'quiz', label: Text('Quiz')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            if (_type == 'note')
              TextField(
                controller: _noteCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Note content *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            if (_type == 'link') ...[
              Text(
                'Attach one or more links',
                style: AppTypography.caption.copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: 8),
              ..._linkDrafts.asMap().entries.map((entry) {
                final index = entry.key;
                final draft = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surface200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Link ${index + 1}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_linkDrafts.length > 1)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _linkDrafts.removeAt(index).dispose();
                                  });
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                          ],
                        ),
                        TextField(
                          controller: draft.urlCtrl,
                          decoration: InputDecoration(
                            labelText: 'URL *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: draft.titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Link title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _linkDrafts.add(_LinkDraftControllers())),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add another link'),
                ),
              ),
            ],
            if (_type == 'file') ...[
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label:
                    Text(_pickedFile == null ? 'Pick File' : _pickedFile!.name),
              ),
            ],
            if (_type == 'quiz') ...[
              TextField(
                controller: _quizTitleCtrl,
                decoration: InputDecoration(
                  labelText: 'Quiz title *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _quizDurationCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes, optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _addQuestionDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Question'),
              ),
              if (_questions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${_questions.length} question(s) added'),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.errorRed)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMedium,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Save',
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Future<String?> _showInputDialog(
    BuildContext context, String title, String hint) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Create')),
      ],
    ),
  );
}

class _QuestionDraft {
  const _QuestionDraft({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.marks,
  });

  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final int marks;
}

class _LinkDraftControllers {
  _LinkDraftControllers()
      : urlCtrl = TextEditingController(),
        titleCtrl = TextEditingController();

  final TextEditingController urlCtrl;
  final TextEditingController titleCtrl;

  void dispose() {
    urlCtrl.dispose();
    titleCtrl.dispose();
  }
}

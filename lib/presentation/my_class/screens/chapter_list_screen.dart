// 🆕 NEW FILE
// lib/presentation/my_class/screens/chapter_list_screen.dart  [Mobile App]
// My Class — Chapter List.
// Shows chapters for a selected subject.  Tapping a chapter opens topic list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/my_class/my_class_models.dart';
import '../../../providers/my_class_provider.dart';
import 'topic_list_screen.dart';

class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({
    super.key,
    required this.subject,
    required this.isReadOnly,
    this.childId,
  });

  final SubjectSummary subject;
  final bool isReadOnly;
  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(myClassChaptersProvider((
      subjectId: subject.subjectId,
      standardId: subject.standardId,
      sectionId: subject.sectionId,
      academicYearId: subject.academicYearId,
      childId: childId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: Text(subject.subjectName, style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface50,
        elevation: 0,
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed)),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return Center(
              child: Text(
                'No chapters yet.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myClassChaptersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final ch = chapters[i];
                return _ChapterTile(
                  chapter: ch,
                  index: i + 1,
                  isReadOnly: isReadOnly,
                  childId: childId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.index,
    required this.isReadOnly,
    this.childId,
  });

  final ChapterModel chapter;
  final int index;
  final bool isReadOnly;
  final String? childId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: chapter.isLocked
            ? null
            : () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TopicListScreen(
                    chapter: chapter,
                    isReadOnly: isReadOnly,
                    childId: childId,
                  ),
                ));
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navyMedium.withOpacity(0.1),
                child: Text(
                  '$index',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.navyMedium),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.title,
                        style: AppTypography.labelLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (chapter.description != null)
                      Text(chapter.description!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    Text(
                      '${chapter.topicCount} topic${chapter.topicCount == 1 ? '' : 's'}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              if (chapter.isLocked)
                const Icon(Icons.lock_outline, size: 16, color: AppColors.grey400)
              else
                const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
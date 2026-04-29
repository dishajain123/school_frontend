// 🆕 NEW FILE
// lib/presentation/my_class/screens/topic_list_screen.dart  [Mobile App]
// My Class — Topic List + Content Item viewer.
// Shows topics for a chapter; tapping a topic expands its content items.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/my_class/my_class_models.dart';
import '../../../providers/my_class_provider.dart';
import 'quiz_attempt_screen.dart';

class TopicListScreen extends ConsumerWidget {
  const TopicListScreen({
    super.key,
    required this.chapter,
    required this.isReadOnly,
    this.childId,
  });

  final ChapterModel chapter;
  final bool isReadOnly;
  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(myClassTopicsProvider((
      chapterId: chapter.id,
      childId: childId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: Text(chapter.title, style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface50,
        elevation: 0,
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed))),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
                child: Text('No topics yet.',
                    style:
                        AppTypography.bodySmall.copyWith(color: AppColors.grey500)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myClassTopicsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, i) => _TopicExpansionTile(
                topic: topics[i],
                isReadOnly: isReadOnly,
                childId: childId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicExpansionTile extends ConsumerStatefulWidget {
  const _TopicExpansionTile({
    required this.topic,
    required this.isReadOnly,
    this.childId,
  });

  final TopicModel topic;
  final bool isReadOnly;
  final String? childId;

  @override
  ConsumerState<_TopicExpansionTile> createState() =>
      _TopicExpansionTileState();
}

class _TopicExpansionTileState extends ConsumerState<_TopicExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(widget.topic.title,
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${widget.topic.contentCount} item${widget.topic.contentCount == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(color: AppColors.grey500),
          ),
          trailing: widget.topic.isLocked
              ? const Icon(Icons.lock_outline, size: 16, color: AppColors.grey400)
              : Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          children: widget.topic.isLocked
              ? [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('This topic is locked.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  )
                ]
              : [_ContentList(topic: widget.topic, isReadOnly: widget.isReadOnly, childId: widget.childId)],
        ),
      ),
    );
  }
}

class _ContentList extends ConsumerWidget {
  const _ContentList({
    required this.topic,
    required this.isReadOnly,
    this.childId,
  });

  final TopicModel topic;
  final bool isReadOnly;
  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(myClassContentProvider((
      topicId: topic.id,
      childId: childId,
    )));

    return contentAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(e.toString(),
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.errorRed)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('No content yet.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
          );
        }
        return Column(
          children: items
              .map((item) => _ContentItemTile(
                    item: item,
                    isReadOnly: isReadOnly,
                    childId: childId,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ContentItemTile extends StatelessWidget {
  const _ContentItemTile({
    required this.item,
    required this.isReadOnly,
    this.childId,
  });

  final ContentItemModel item;
  final bool isReadOnly;
  final String? childId;

  IconData get _icon {
    switch (item.contentType) {
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

  Color get _iconColor {
    switch (item.contentType) {
      case 'file':
        return AppColors.errorRed;
      case 'link':
        return AppColors.infoBlue;
      case 'quiz':
        return AppColors.subjectPhysics;
      default:
        return AppColors.navyMedium;
    }
  }

  void _onTap(BuildContext context) {
    if (item.isLocked) return;
    switch (item.contentType) {
      case 'note':
        _showNote(context);
        break;
      case 'file':
        _openFile(context);
        break;
      case 'link':
        _openLink(context);
        break;
      case 'quiz':
        if (!isReadOnly && item.quizId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => QuizAttemptScreen(
              quizId: item.quizId!,
              childId: childId,
              isReadOnly: isReadOnly,
            ),
          ));
        }
        break;
    }
  }

  void _showNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title ?? 'Note',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(item.noteText ?? '',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.grey700)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final url = item.fileUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File URL not available')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLink(BuildContext context) async {
    final url = item.linkUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(_icon, color: _iconColor, size: 22),
      title: Text(
        item.title ??
            item.linkTitle ??
            item.fileName ??
            item.contentType,
        style: AppTypography.bodyMedium,
      ),
      subtitle: Text(
        item.contentType.toUpperCase(),
        style: AppTypography.caption.copyWith(color: AppColors.grey500),
      ),
      trailing: item.isLocked
          ? const Icon(Icons.lock_outline, size: 14, color: AppColors.grey400)
          : (item.contentType == 'quiz' && isReadOnly)
              ? Text('Past year',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.warningAmber))
              : const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.grey400),
      onTap: () => _onTap(context),
    );
  }
}
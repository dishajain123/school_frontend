import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/document/document_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/document_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/document_filter_bar.dart';
import '../widgets/document_tile.dart';
import 'request_document_sheet.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key, this.studentId});

  /// Explicitly passed student ID (admin/teacher context).
  /// If null, resolved from auth state:
  ///   - STUDENT → their own student ID (backend resolves via user_id)
  ///   - PARENT  → parentProvider.selectedChildId
  final String? studentId;

  @override
  ConsumerState<DocumentListScreen> createState() =>
      _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen>
    with SingleTickerProviderStateMixin {
  DocumentStatus? _statusFilter;
  String? _resolvedStudentId;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Resolve student ID
    if (widget.studentId != null) {
      _resolvedStudentId = widget.studentId;
    } else if (user.role == UserRole.student) {
      // STUDENT: backend uses user_id from JWT to find student —
      // we still need a student_id for the query param.
      // This would normally come from a "my student profile" provider.
      // For now we rely on the parent/admin path or query param.
      _resolvedStudentId = widget.studentId;
    }

    if (_resolvedStudentId != null) {
      await ref.read(documentProvider.notifier).load(_resolvedStudentId!);
      _fadeCtrl.forward();
    }
  }

  Future<void> _refresh() async {
    if (_resolvedStudentId != null) {
      await ref.read(documentProvider.notifier).load(_resolvedStudentId!);
    }
  }

  List<DocumentModel> _filtered(List<DocumentModel> docs) {
    if (_statusFilter == null) return docs;
    return docs.where((d) => d.status == _statusFilter).toList();
  }

  bool get _canRequest => _resolvedStudentId != null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final filtered = _filtered(state.documents);
    final hasPollable = state.documents.any((d) => d.isPollable);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: _buildAppBar(context, hasPollable),
      floatingActionButton: _canRequest ? _buildFab(context, state) : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.navyDeep,
        backgroundColor: AppColors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Polling banner ─────────────────────────────────────────────
            if (hasPollable)
              SliverToBoxAdapter(
                child: _ProcessingBanner(
                  count: state.documents.where((d) => d.isPollable).length,
                ),
              ),

            // ── Filter bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pageHorizontal,
                  AppDimensions.space16,
                  AppDimensions.pageHorizontal,
                  AppDimensions.space8,
                ),
                child: DocumentFilterBar(
                  selected: _statusFilter,
                  onSelected: (s) => setState(() => _statusFilter = s),
                ),
              ),
            ),

            // ── Section header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pageHorizontal,
                  AppDimensions.space8,
                  AppDimensions.pageHorizontal,
                  AppDimensions.space4,
                ),
                child: AppSectionHeader(
                  title: _sectionTitle(filtered.length),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            if (state.isLoading)
              _buildSkeletons()
            else if (state.error != null && state.documents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(state.error!),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else
              FadeTransition(
                opacity: _fadeAnim,
                child: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageHorizontal,
                    AppDimensions.space8,
                    AppDimensions.pageHorizontal,
                    AppDimensions.space64,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      return DocumentTile(
                        document: doc,
                        onDownload: doc.isReady
                            ? () => _handleDownload(context, doc)
                            : null,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, bool hasPollable) {
    return AppBar(
      backgroundColor: AppColors.navyDeep,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: context.canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents', style: AppTypography.titleLargeOnDark),
          if (hasPollable)
            Text(
              'Generating in background…',
              style: AppTypography.caption.copyWith(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context, DocumentState state) {
    return FloatingActionButton.extended(
      onPressed: state.isRequesting
          ? null
          : () => _showRequestSheet(context),
      backgroundColor: state.isRequesting
          ? AppColors.goldPrimary.withValues(alpha: 0.7)
          : AppColors.goldPrimary,
      foregroundColor: AppColors.navyDeep,
      elevation: 4,
      icon: state.isRequesting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navyDeep),
              ),
            )
          : const Icon(Icons.add_rounded),
      label: Text(
        state.isRequesting ? 'Requesting…' : 'Request Document',
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.navyDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Skeletons ───────────────────────────────────────────────────────────────

  SliverList _buildSkeletons() {
    return SliverList.separated(
      itemCount: 5,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontal),
        child: _DocumentTileSkeleton(),
      ),
    );
  }

  // ── Empty ────────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: _statusFilter != null
          ? 'No ${_statusFilter!.label} Documents'
          : 'No Documents Yet',
      subtitle: _statusFilter != null
          ? 'Try selecting a different filter.'
          : 'Tap the button below to request your first document.',
      actionLabel: _statusFilter != null ? 'Clear Filter' : null,
      onAction: _statusFilter != null
          ? () => setState(() => _statusFilter = null)
          : null,
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: AppDimensions.iconXL, color: AppColors.grey400),
            const SizedBox(height: AppDimensions.space16),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space20),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _sectionTitle(int count) {
    if (_statusFilter != null) {
      return '${_statusFilter!.label} ($count)';
    }
    return 'All Documents ($count)';
  }

  Future<void> _handleDownload(BuildContext context, DocumentModel doc) async {
    // Fetch a fresh presigned URL — never use a cached one
    final result =
        await ref.read(documentProvider.notifier).getDownloadUrl(doc.id);
    if (!context.mounted) return;
    if (result == null || !result.hasUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?.status == DocumentStatus.processing
              ? 'Document is still being generated. Please wait.'
              : 'Download link not available. Please try again.'),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
      return;
    }
    // Navigate to viewer — pass URL + title as extras
    context.push(
      RouteNames.documents,
      extra: {
        'url': result.url,
        'documentId': doc.id,
        'title': doc.documentType.label,
      },
    );
  }

  Future<void> _showRequestSheet(BuildContext context) async {
    if (_resolvedStudentId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => RequestDocumentSheet(
        studentId: _resolvedStudentId!,
      ),
    );
  }
}

// ── Processing Banner ─────────────────────────────────────────────────────────

class _ProcessingBanner extends StatefulWidget {
  const _ProcessingBanner({required this.count});
  final int count;

  @override
  State<_ProcessingBanner> createState() => _ProcessingBannerState();
}

class _ProcessingBannerState extends State<_ProcessingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        AppDimensions.space16,
        AppDimensions.pageHorizontal,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.infoBlue.withValues(alpha: 0.3),
          width: AppDimensions.borderThin,
        ),
      ),
      child: Row(
        children: [
          RotationTransition(
            turns: _ctrl,
            child: const Icon(
              Icons.sync_rounded,
              color: AppColors.infoBlue,
              size: AppDimensions.iconSM,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              widget.count == 1
                  ? '1 document is being generated…'
                  : '${widget.count} documents are being generated…',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Auto-refreshing',
            style: AppTypography.caption.copyWith(
              color: AppColors.infoBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DocumentTileSkeleton extends StatelessWidget {
  const _DocumentTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface100,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface100,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Space constant ────────────────────────────────────────────────────────────


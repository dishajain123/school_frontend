// presentation/documents/screens/document_list_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/document/document_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/repositories/student_repository.dart';
import '../widgets/document_filter_bar.dart';
import '../widgets/document_tile.dart';
import 'request_document_sheet.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  DocumentStatus? _statusFilter;
  String? _resolvedStudentId;
  bool _isRequestSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() => super.dispose();

  Future<void> _init() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (widget.studentId != null) {
      _resolvedStudentId = widget.studentId;
    } else if (user.role == UserRole.student) {
      try {
        final student =
            await ref.read(studentRepositoryProvider).getMyProfile();
        if (!mounted) return;
        _resolvedStudentId = student.id;
      } catch (_) {
        final result = await ref
            .read(studentRepositoryProvider)
            .list(page: 1, pageSize: 1);
        if (!mounted) return;
        _resolvedStudentId =
            result.items.isNotEmpty ? result.items.first.id : null;
      }
    } else if (user.role == UserRole.parent) {
      _resolvedStudentId = ref.read(selectedChildIdProvider);
      if (_resolvedStudentId == null) {
        await ref.read(childrenNotifierProvider.notifier).loadMyChildren();
        if (!mounted) return;
        _resolvedStudentId = ref.read(selectedChildIdProvider);
      }
    } else if (user.role == UserRole.principal ||
        user.role == UserRole.superadmin) {
      _resolvedStudentId = null;
    }

    await ref.read(documentProvider.notifier).load(_resolvedStudentId);
  }

  Future<void> _refresh() async {
    await ref.read(documentProvider.notifier).load(_resolvedStudentId);
  }

  List<DocumentModel> _filtered(List<DocumentModel> docs) {
    if (_statusFilter == null) return docs;
    return docs.where((d) => d.status == _statusFilter).toList();
  }

  bool _isVerifiable(DocumentModel doc) {
    final hasFile = (doc.fileKey ?? '').trim().isNotEmpty;
    return doc.status == DocumentStatus.processing && hasFile;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canGenerate = user?.hasPermission('document:generate') ?? false;
    final canManage = user?.hasPermission('document:manage') ?? false;
    final canUpload = _resolvedStudentId != null &&
        user != null &&
        (user.role == UserRole.student ||
            user.role == UserRole.parent ||
            user.role == UserRole.teacher) &&
        (canGenerate || canManage);
    // Students/parents can request documents (e.g., ID card) from admin.
    final canRequest = _resolvedStudentId != null &&
        user != null &&
        (user.role == UserRole.student || user.role == UserRole.parent) &&
        (canGenerate || canManage);
    final canVerify = user != null &&
        canManage &&
        (user.role == UserRole.principal || user.role == UserRole.superadmin);
    final canManageRequirements = canVerify;

    final state = ref.watch(documentProvider);
    final filtered = _filtered(state.documents);
    final hasPendingVerification =
        state.documents.any((d) => d.status == DocumentStatus.processing);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: _buildAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (canRequest || canUpload)
          ? _buildFab(context, state, canRequest, canUpload)
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.navyDeep,
        backgroundColor: AppColors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (hasPendingVerification)
              SliverToBoxAdapter(
                child: _ProcessingBanner(
                  count: state.documents
                      .where((d) => d.status == DocumentStatus.processing)
                      .length,
                ),
              ),
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
            if (_resolvedStudentId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pageHorizontal,
                    0,
                    AppDimensions.pageHorizontal,
                    AppDimensions.space8,
                  ),
                  child: _RequiredDocsPanel(
                    items: state.requiredStatus,
                    canManageRequirements: canManageRequirements,
                    onManageTap: canManageRequirements
                        ? () => _showManageRequiredDocsSheet(context)
                        : null,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pageHorizontal,
                  AppDimensions.space4,
                  AppDimensions.pageHorizontal,
                  AppDimensions.space4,
                ),
                child: _SectionLabel(
                  title: _sectionTitle(filtered.length),
                ),
              ),
            ),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pageHorizontal,
                  AppDimensions.space8,
                  AppDimensions.pageHorizontal,
                  120,
                ),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.space12),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DocumentTile(
                          document: doc,
                          onDownload: doc.isReady
                              ? () => _handleDownload(context, doc)
                              : null,
                        ),
                        if (canVerify && _isVerifiable(doc))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _rejectDocumentWithReason(context, doc),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.errorRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verifyDocument(doc, true),
                                    icon: const Icon(Icons.check_rounded,
                                        size: 16),
                                    label: const Text('Verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.successGreen,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (canVerify &&
                            doc.status == DocumentStatus.processing &&
                            !_isVerifiable(doc))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Awaiting uploaded file before verification.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navyDeep,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.dashboard);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents', style: AppTypography.titleLargeOnDark),
        ],
      ),
    );
  }

  Widget _buildFab(
    BuildContext context,
    DocumentState state,
    bool canRequest,
    bool canUpload,
  ) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom +
        kBottomNavigationBarHeight +
        8;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth - (AppDimensions.space16 * 2);
    final isCompactMobile = screenWidth < 380;

    if (canRequest && !canUpload) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDimensions.space8 + bottomInset),
        child: SizedBox(
          width: maxWidth.clamp(0, 420).toDouble(),
          child: _requestFab(context, state),
        ),
      );
    }
    if (!canRequest && canUpload) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDimensions.space8 + bottomInset),
        child: SizedBox(
          width: maxWidth.clamp(0, 420).toDouble(),
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: state.isUploading ? null : () => _pickAndUpload(context),
            backgroundColor: AppColors.navyDeep,
            foregroundColor: AppColors.white,
            icon: state.isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(
              state.isUploading ? 'Uploading…' : 'Upload Document',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.space8 + bottomInset),
      child: SizedBox(
        width: maxWidth.clamp(0, 420).toDouble(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed:
                        state.isUploading ? null : () => _pickAndUpload(context),
                    backgroundColor: AppColors.navyDeep,
                    foregroundColor: AppColors.white,
                    icon: state.isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(isCompactMobile ? 'Upload' : 'Upload Document'),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FloatingActionButton.extended(
                    heroTag: 'request-doc-fab',
                    onPressed:
                        state.isRequesting ? null : () => _showRequestSheet(context),
                    backgroundColor: state.isRequesting
                        ? AppColors.goldPrimary.withValues(alpha: 0.7)
                        : AppColors.goldPrimary,
                    foregroundColor: AppColors.navyDeep,
                    icon: state.isRequesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.navyDeep),
                            ),
                          )
                        : const Icon(Icons.description_outlined),
                    label: Text(isCompactMobile ? 'Request' : 'Request Document'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestFab(
    BuildContext context,
    DocumentState state,
  ) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: state.isRequesting ? null : () => _showRequestSheet(context),
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

  SliverList _buildSkeletons() {
    return SliverList.separated(
      itemCount: 5,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontal),
        child: _DocumentTileSkeleton(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 30,
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              _statusFilter != null
                  ? 'No ${_statusFilter!.label} Documents'
                  : 'No Documents Yet',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              _statusFilter != null
                  ? 'Try selecting a different filter.'
                  : 'Tap request or upload to add first document.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
            if (_statusFilter != null) ...[
              const SizedBox(height: AppDimensions.space16),
              OutlinedButton(
                onPressed: () => setState(() => _statusFilter = null),
                child: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 32, color: AppColors.grey400),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space20),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _sectionTitle(int count) {
    if (_statusFilter != null) {
      return '${_statusFilter!.label} ($count)';
    }
    return 'All Documents ($count)';
  }

  Future<void> _handleDownload(BuildContext context, DocumentModel doc) async {
    DocumentDownloadResponse? result;
    try {
      result = await ref.read(documentProvider.notifier).getDownloadUrl(doc.id);
    } catch (_) {
      result = null;
    }
    if (!context.mounted) return;
    if (result == null || !result.hasUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?.status == DocumentStatus.processing
              ? 'Document is still under verification. Please wait.'
              : 'Download link not available. Please try again.'),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc.documentType.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open or copy this secure document link:'),
            const SizedBox(height: 8),
            SelectableText(
              result!.url!,
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result!.url!));
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (!mounted) return;
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestSheet(BuildContext context) async {
    if (_isRequestSheetOpen) return;
    if (_resolvedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a child first from dashboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _isRequestSheetOpen = true;
    RequiredDocumentModel? requested;
    final allowedRequirements = ref.read(documentProvider).requiredDocuments;
    try {
      requested = await showModalBottomSheet<RequiredDocumentModel?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.86,
          child: RequestDocumentSheet(
            studentId: _resolvedStudentId!,
            allowedRequirements:
                allowedRequirements.isEmpty ? null : allowedRequirements,
          ),
        ),
      );
    } finally {
      _isRequestSheetOpen = false;
    }
    if (!context.mounted || requested == null) return;
    final requestedLabel = requested.documentType == DocumentType.other
        ? (((requested.note ?? '').trim().isNotEmpty)
            ? requested.note!.trim()
            : requested.documentType.label)
        : requested.documentType.label;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$requestedLabel requested! Generating in background.',
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  bool _canUploadTypeForRole(UserRole role, DocumentType type) {
    if (role == UserRole.teacher) return type == DocumentType.idCard;
    if (role == UserRole.parent || role == UserRole.student) {
      return type != DocumentType.idCard;
    }
    return true;
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    if (_resolvedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a child first from dashboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final requiredDocs = ref.read(documentProvider).requiredDocuments;
    final baseAllowedTypes = DocumentType.values
        .where((type) => _canUploadTypeForRole(user.role, type))
        .toSet();
    List<RequiredDocumentModel> allowedDocs;
    if ((user.role == UserRole.parent || user.role == UserRole.student) &&
        requiredDocs.isNotEmpty) {
      allowedDocs = requiredDocs
          .where((r) => baseAllowedTypes.contains(r.documentType))
          .toList(growable: false);
    } else {
      allowedDocs = baseAllowedTypes
          .map((t) => RequiredDocumentModel(documentType: t))
          .toList(growable: false);
    }
    if (allowedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No uploadable document types available right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    var selectedDoc = allowedDocs.first;
    final pickedDoc = await showModalBottomSheet<RequiredDocumentModel>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Select Document Type'),
          ),
          ...allowedDocs.map(
            (doc) => ListTile(
              leading: Icon(doc.documentType.icon, color: doc.documentType.color),
              title: Text(doc.documentType == DocumentType.other &&
                      (doc.note ?? '').trim().isNotEmpty
                  ? doc.note!.trim()
                  : doc.documentType.label),
              onTap: () => Navigator.of(ctx).pop(doc),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted || pickedDoc == null) return;
    selectedDoc = pickedDoc;

    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        // Avoid loading big bytes into memory on mobile/desktop; keep bytes for web.
        withData: kIsWeb,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File picker failed: $e'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;

    final ok = await ref.read(documentProvider.notifier).uploadDocument(
          studentId: _resolvedStudentId!,
          documentType: selectedDoc.documentType,
          note: selectedDoc.documentType == DocumentType.other
              ? selectedDoc.note
              : null,
          file: file,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${selectedDoc.documentType == DocumentType.other && (selectedDoc.note ?? '').trim().isNotEmpty ? selectedDoc.note!.trim() : selectedDoc.documentType.label} uploaded successfully.'
              : (ref.read(documentProvider).error ?? 'Upload failed.'),
        ),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyDocument(DocumentModel document, bool approve) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final hasFile = (document.fileKey ?? '').trim().isNotEmpty;
    if (!hasFile) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot verify yet. Uploaded file is missing for this document.',
          ),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await ref.read(documentProvider.notifier).verifyDocument(
          documentId: document.id,
          approve: approve,
        );
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (approve ? 'Document verified.' : 'Document rejected.')
            : (ref.read(documentProvider).error ?? 'Update failed.')),
        backgroundColor: ok
            ? (approve ? AppColors.successGreen : AppColors.warningAmber)
            : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _rejectDocumentWithReason(
      BuildContext context, DocumentModel document) async {
    final hasFile = (document.fileKey ?? '').trim().isNotEmpty;
    if (!hasFile) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot review yet. Uploaded file is missing for this document.',
          ),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;

    final ok = await ref.read(documentProvider.notifier).verifyDocument(
          documentId: document.id,
          approve: false,
          reason: reason,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Document rejected. Student/parent notified to re-upload.'
            : (ref.read(documentProvider).error ?? 'Update failed.')),
        backgroundColor: ok ? AppColors.warningAmber : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showManageRequiredDocsSheet(BuildContext context) async {
    final current = ref.read(documentProvider).requiredDocuments;
    final rows = current.isEmpty
        ? <RequiredDocumentModel>[
            const RequiredDocumentModel(documentType: DocumentType.idCard),
          ]
        : List<RequiredDocumentModel>.from(current);

    final saveTapped = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Required Documents',
                          style: AppTypography.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...rows.asMap().entries.map(
                    (entry) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<DocumentType>(
                                    value: entry.value.documentType,
                                    decoration: const InputDecoration(
                                      labelText: 'Document Type',
                                    ),
                                    items: DocumentType.values
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.label),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (next) {
                                      if (next == null) return;
                                      setModalState(
                                        () => rows[entry.key] =
                                            RequiredDocumentModel(
                                          documentType: next,
                                          isMandatory: true,
                                          note: entry.value.note,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: rows.length <= 1
                                      ? null
                                      : () => setModalState(
                                            () => rows.removeAt(entry.key),
                                          ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: entry.value.note ?? '',
                              onChanged: (v) =>
                                  rows[entry.key] = RequiredDocumentModel(
                                documentType: rows[entry.key].documentType,
                                isMandatory: true,
                                note: v,
                              ),
                              decoration: InputDecoration(
                                labelText: rows[entry.key].documentType ==
                                        DocumentType.other
                                    ? 'Custom Document Name *'
                                    : 'Instruction (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => setModalState(
                        () => rows.add(
                          const RequiredDocumentModel(
                            documentType: DocumentType.other,
                            isMandatory: true,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Document'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final payload = rows
        .map(
          (row) => RequiredDocumentModel(
            documentType: row.documentType,
            isMandatory: true,
            note: (row.note ?? '').trim().isEmpty ? null : row.note!.trim(),
          ),
        )
        .toList(growable: false);
    if (saveTapped != true) return;
    if (!context.mounted) return;
    for (final item in payload) {
      if (item.documentType == DocumentType.other &&
          (item.note ?? '').trim().isEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Custom name is required for Other document type.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await ref
        .read(documentProvider.notifier)
        .saveRequiredDocuments(payload);
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Required documents updated.'
            : (ref.read(documentProvider).error ??
                'Failed to save requirements')),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (ok && _resolvedStudentId != null) {
      await ref
          .read(documentProvider.notifier)
          .refreshRequiredStatus(_resolvedStudentId!);
    }
  }
}

class _RequiredDocsPanel extends StatelessWidget {
  const _RequiredDocsPanel({
    required this.items,
    required this.canManageRequirements,
    this.onManageTap,
  });

  final List<RequiredDocumentStatusModel> items;
  final bool canManageRequirements;
  final VoidCallback? onManageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Required Documents', style: AppTypography.titleMedium),
              const Spacer(),
              if (canManageRequirements)
                TextButton(
                  onPressed: onManageTap,
                  child: const Text('Manage'),
                ),
            ],
          ),
          if (items.isEmpty)
            Text(
              canManageRequirements
                  ? 'No required docs configured.'
                  : 'No required docs configured by school.',
              style: AppTypography.bodySmall,
            )
          else
            ...items.map((item) {
              final status = item.latestStatus;
              final summary = item.isCompleted
                  ? 'Approved'
                  : item.needsReupload
                      ? 'Rejected - Reupload needed'
                      : status == null
                          ? 'Not uploaded'
                          : status.label;
              final color = item.isCompleted
                  ? AppColors.successGreen
                  : item.needsReupload
                      ? AppColors.errorRed
                      : AppColors.warningAmber;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.documentType.icon,
                    color: item.documentType.color),
                title: Text(
                  item.documentType == DocumentType.other &&
                          (item.note ?? '').trim().isNotEmpty
                      ? item.note!.trim()
                      : item.documentType.label,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary),
                    if ((item.note ?? '').trim().isNotEmpty)
                      Text('Instruction: ${item.note!.trim()}'),
                    if ((item.reviewNote ?? '').trim().isNotEmpty)
                      Text('Reason: ${item.reviewNote!.trim()}'),
                  ],
                ),
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Processing Banner ─────────────────────────────────────────────────────────

class _ProcessingBanner extends StatelessWidget {
  const _ProcessingBanner({required this.count});
  final int count;

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
          color: AppColors.infoBlue.withValues(alpha: 0.25),
          width: AppDimensions.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync_rounded,
            color: AppColors.infoBlue,
            size: AppDimensions.iconSM,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              count == 1
                  ? '1 document is pending principal verification.'
                  : '$count documents are pending principal verification.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space8,
              vertical: AppDimensions.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              'Pending Review',
              style: AppTypography.caption.copyWith(
                color: AppColors.infoBlue,
                fontWeight: FontWeight.w600,
              ),
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surface100,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  height: 10,
                  width: 90,
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
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
        ],
      ),
    );
  }
}

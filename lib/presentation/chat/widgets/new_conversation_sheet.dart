import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../presentation/common/widgets/app_button.dart';
import '../../../presentation/common/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';

class NewConversationSheet extends ConsumerStatefulWidget {
  const NewConversationSheet({super.key});

  @override
  ConsumerState<NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState
    extends ConsumerState<NewConversationSheet> {
  ConversationType _type = ConversationType.oneToOne;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  List<_UserResult> _searchResults = [];
  _UserResult? _selectedUser;
  bool _isSearching = false;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_isCreating) return false;
    if (_type == ConversationType.oneToOne) return _selectedUser != null;
    return _groupNameController.text.trim().isNotEmpty &&
        _selectedUser != null;
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results =
          await ref.read(chatRepositoryProvider).searchUsers(query: query);
      final currentId = ref.read(currentUserProvider)?.id;
      setState(() {
        _searchResults = results
            .where((u) => u.id != currentId)
            .map((u) => _UserResult(id: u.id, display: u.displayName, role: u.role))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      ConversationModel? conversation;
      final notifier =
          ref.read(conversationNotifierProvider.notifier);

      if (_type == ConversationType.oneToOne) {
        conversation = await notifier.startOneToOne(_selectedUser!.id);
      } else {
        conversation = await notifier.createGroup(
          name: _groupNameController.text.trim(),
          participantIds: [_selectedUser!.id],
        );
      }

      if (mounted) Navigator.of(context).pop(conversation);
    } on AppException catch (e) {
      setState(() {
        _isCreating = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canGroup = user?.hasPermission('chat:group_manage') ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppDimensions.space12),
              width: AppDimensions.dragHandleWidth,
              height: AppDimensions.dragHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.surface200,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Conversation',
                    style: AppTypography.headlineSmall),
                const SizedBox(height: AppDimensions.space16),
                // Type selector
                if (canGroup) ...[
                  _TypeSelector(
                    selected: _type,
                    onChanged: (t) => setState(() {
                      _type = t;
                      _selectedUser = null;
                      _searchResults = [];
                      _searchController.clear();
                    }),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],
                // Group name (group only)
                if (_type == ConversationType.group) ...[
                  AppTextField(
                    label: 'Group Name',
                    hint: 'e.g. Class 10-A Teachers',
                    controller: _groupNameController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                ],
                // Search field
                AppTextField(
                  label: _type == ConversationType.oneToOne
                      ? 'Find User'
                      : 'Add Participant',
                  hint: 'Search by email or phone…',
                  controller: _searchController,
                  prefixIconData: Icons.search_rounded,
                  onChanged: _search,
                ),
                const SizedBox(height: AppDimensions.space8),
                // Selected user chip
                if (_selectedUser != null)
                  _SelectedChip(
                    user: _selectedUser!,
                    onRemove: () => setState(() => _selectedUser = null),
                  ),
                // Search results
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.space16),
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  )
                else if (_searchResults.isNotEmpty && _selectedUser == null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length.clamp(0, 5),
                    itemBuilder: (_, i) => _ResultTile(
                      user: _searchResults[i],
                      onTap: () => setState(() {
                        _selectedUser = _searchResults[i];
                        _searchResults = [];
                        _searchController.clear();
                      }),
                    ),
                  ),
                // Error
                if (_error != null) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    _error!,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.errorRed),
                  ),
                ],
                const SizedBox(height: AppDimensions.space24),
                AppButton.primary(
                  label: 'Start Conversation',
                  onTap: _canCreate ? _create : null,
                  isLoading: _isCreating,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final ConversationType selected;
  final ValueChanged<ConversationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ConversationType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: type == ConversationType.oneToOne
                    ? AppDimensions.space8
                    : 0,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.navyDeep
                    : AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type.icon,
                    size: AppDimensions.iconSM,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.grey600,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Text(
                    type.label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.grey600,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.user, required this.onRemove});
  final _UserResult user;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.navyLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded,
              size: AppDimensions.iconSM, color: AppColors.navyMedium),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.display,
                    style: AppTypography.titleSmall,
                    overflow: TextOverflow.ellipsis),
                Text(user.role,
                    style: AppTypography.caption),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: AppDimensions.iconSM, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.user, required this.onTap});
  final _UserResult user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.space8,
          horizontal: AppDimensions.space4,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person_outline_rounded,
                    size: AppDimensions.iconSM, color: AppColors.navyMedium),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.display,
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis),
                  Text(user.role, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(Icons.add_rounded,
                size: AppDimensions.iconSM, color: AppColors.navyMedium),
          ],
        ),
      ),
    );
  }
}

class _UserResult {
  const _UserResult({
    required this.id,
    required this.display,
    required this.role,
  });
  final String id;
  final String display;
  final String role;
}
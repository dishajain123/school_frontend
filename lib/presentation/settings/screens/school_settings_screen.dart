import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/school/school_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/school_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class SchoolSettingsScreen extends ConsumerStatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  ConsumerState<SchoolSettingsScreen> createState() =>
      _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends ConsumerState<SchoolSettingsScreen>
    with SingleTickerProviderStateMixin {
  String? _editingKey;
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolSettingsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final success = await ref.read(schoolSettingsProvider.notifier).saveAll();
    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, 'Settings saved successfully');
    } else {
      final message =
          ref.read(schoolSettingsProvider).error ?? 'Failed to save settings';
      SnackbarUtils.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final settingsState = ref.watch(schoolSettingsProvider);
    final settingsNotifier = ref.read(schoolSettingsProvider.notifier);
    final canManageSettings = (user?.hasPermission('settings:manage') ??
            false) ||
        (user?.role.isSchoolScopedAdmin ?? false);

    if (!canManageSettings) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School Settings', showBack: true),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle:
              'You need permission to manage school settings (e.g. principal or staff admin).',
        ),
      );
    }

    if (settingsState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'School Settings', showBack: true),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppLoading.card(height: 80),
          ),
        ),
      );
    }

    if (settingsState.error != null && settingsState.items.isEmpty) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'School Settings', showBack: true),
        body: AppErrorState(
          message: settingsState.error!,
          onRetry: () => settingsNotifier.load(),
        ),
      );
    }

    if (settingsState.items.isEmpty) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School Settings', showBack: true),
        body: AppEmptyState(
          icon: Icons.tune_outlined,
          title: 'No settings found',
          subtitle: 'No configurable settings are available right now.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'School Settings', showBack: true),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoBanner(),
                  const SizedBox(height: 16),
                  ...settingsState.items.map((item) {
                    final key = item.settingKey;
                    final value = settingsState.edits[key] ?? item.settingValue;
                    final isEditing = _editingKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SettingCard(
                        item: item,
                        value: value,
                        isEditing: isEditing,
                        onTap: () => setState(
                            () => _editingKey = isEditing ? null : key),
                        onChanged: (newValue) =>
                            settingsNotifier.setValue(key, newValue),
                        onDone: () => setState(() => _editingKey = null),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _SaveBar(
              isSaving: settingsState.isSaving,
              onSave: _saveAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_outlined, size: 15, color: AppColors.infoBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap any setting to edit. Press "Save All" when done.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.isSaving, required this.onSave});
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: 'Save All Settings',
        onTap: isSaving ? null : onSave,
        isLoading: isSaving,
        icon: Icons.save_outlined,
      ),
    );
  }
}

class _SettingCard extends StatefulWidget {
  const _SettingCard({
    required this.item,
    required this.value,
    required this.isEditing,
    required this.onTap,
    required this.onChanged,
    required this.onDone,
  });

  final SchoolSettingModel item;
  final String value;
  final bool isEditing;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SettingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_controller.selection.isValid) {
      _controller.text = widget.value;
    } else if (oldWidget.value != widget.value && !widget.isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isBoolean {
    final lower = widget.value.toLowerCase();
    return lower == 'true' || lower == 'false';
  }

  bool get _isPercentLike {
    final key = widget.item.settingKey.toLowerCase();
    final value = double.tryParse(widget.value);
    return (key.contains('percent') ||
            key.contains('percentage') ||
            key.contains('threshold')) &&
        value != null;
  }

  String _prettyLabel(String key) {
    return key
        .split('_')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isEditing
                ? AppColors.navyMedium.withValues(alpha: 0.4)
                : AppColors.surface100,
            width: widget.isEditing ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep
                  .withValues(alpha: widget.isEditing ? 0.08 : 0.04),
              blurRadius: widget.isEditing ? 14 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isEditing
                          ? AppColors.navyDeep.withValues(alpha: 0.1)
                          : AppColors.surface100,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.tune_outlined,
                      size: 15,
                      color: widget.isEditing
                          ? AppColors.navyDeep
                          : AppColors.grey500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _prettyLabel(widget.item.settingKey),
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isEditing
                          ? AppColors.navyDeep.withValues(alpha: 0.1)
                          : AppColors.surface50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isEditing ? Icons.edit : Icons.edit_outlined,
                      size: 14,
                      color: widget.isEditing
                          ? AppColors.navyDeep
                          : AppColors.grey400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.isEditing)
                _buildEditor()
              else
                Text(
                  widget.value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grey700,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    if (_isBoolean) {
      final boolValue = widget.value.toLowerCase() == 'true';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            Switch.adaptive(
              value: boolValue,
              onChanged: (value) => widget.onChanged(value.toString()),
              activeColor: AppColors.navyDeep,
            ),
            const SizedBox(width: 8),
            Text(
              boolValue ? 'Enabled' : 'Disabled',
              style: AppTypography.bodyMedium.copyWith(
                color: boolValue ? AppColors.navyDeep : AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_isPercentLike) {
      final initial = (double.tryParse(widget.value) ?? 0).clamp(0, 100);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value: initial.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: AppColors.navyDeep,
            label: '${initial.toStringAsFixed(0)}%',
            onChanged: (value) =>
                widget.onChanged(value.toStringAsFixed(0)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${initial.toStringAsFixed(0)}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        AppTextField(
          controller: _controller,
          label: 'Value',
          hint: 'Enter setting value',
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navyDeep,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Done',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
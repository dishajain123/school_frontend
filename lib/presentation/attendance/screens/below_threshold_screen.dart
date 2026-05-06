import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';

class BelowThresholdScreen extends ConsumerStatefulWidget {
  const BelowThresholdScreen({super.key});

  @override
  ConsumerState<BelowThresholdScreen> createState() => _BelowThresholdScreenState();
}

class _BelowThresholdScreenState extends ConsumerState<BelowThresholdScreen> {
  String? _selectedStandardId;
  String? _activeYearId;
  double _threshold = 75.0;
  BelowThresholdParams? _currentParams;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year = ref.read(activeYearProvider);
      if (year != null) setState(() => _activeYearId = year.id);
    });
  }

  void _load() {
    if (_selectedStandardId == null || _activeYearId == null) {
      SnackbarUtils.showError(context, 'Please select a class first');
      return;
    }
    setState(() {
      _hasFetched = true;
      _currentParams = (
        standardId: _selectedStandardId!,
        academicYearId: _activeYearId!,
        threshold: _threshold,
      );
    });
  }

  Color _thresholdColor(double t) {
    if (t >= 85) return AppColors.successGreen;
    if (t >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Below Threshold', showBack: true),
      body: Column(
        children: [
          _FilterPanel(
            selectedStandardId: _selectedStandardId,
            threshold: _threshold,
            activeYearId: _activeYearId,
            thresholdColor: _thresholdColor(_threshold),
            onStandardChanged: (id) => setState(() => _selectedStandardId = id),
            onThresholdChanged: (val) => setState(() => _threshold = val),
            onThresholdChangeEnd: (_) { if (_hasFetched) _load(); },
            onLoad: _load,
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasFetched || _currentParams == null) {
      return const AppEmptyState(
        icon: Icons.warning_amber_outlined,
        title: 'Configure and search',
        subtitle: 'Select a class, set the threshold, then tap Find Students.',
      );
    }

    final responseAsync = ref.watch(belowThresholdProvider(_currentParams!));
    return responseAsync.when(
      data: (response) {
        if (response.students.isEmpty) {
          return AppEmptyState(
            icon: Icons.check_circle_outline,
            title: 'All clear!',
            subtitle: 'No students are below ${_threshold.toStringAsFixed(0)}% attendance.',
          );
        }
        return _BelowThresholdList(response: response, threshold: _threshold);
      },
      loading: () => AppLoading.fullPage(),
      error: (e, _) => AppErrorState(message: e.toString(), onRetry: _load),
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel({
    required this.selectedStandardId,
    required this.threshold,
    required this.activeYearId,
    required this.thresholdColor,
    required this.onStandardChanged,
    required this.onThresholdChanged,
    required this.onThresholdChangeEnd,
    required this.onLoad,
  });

  final String? selectedStandardId;
  final double threshold;
  final String? activeYearId;
  final Color thresholdColor;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<double> onThresholdChangeEnd;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final year = ref.watch(activeYearProvider);
            if (year == null) return AppLoading.listTile();
            return ref.watch(standardsProvider(year.id)).when(
                  data: (standards) => DropdownButtonFormField<String>(
                    initialValue: selectedStandardId,
                    decoration: _inputDecoration('Select class'),
                    items: standards.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, style: AppTypography.bodyMedium),
                        )).toList(),
                    onChanged: onStandardChanged,
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Threshold: ',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.grey600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: thresholdColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${threshold.toStringAsFixed(0)}%',
                  style: AppTypography.labelMedium.copyWith(
                    color: thresholdColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: thresholdColor,
              thumbColor: thresholdColor,
              overlayColor: thresholdColor.withValues(alpha: 0.12),
              inactiveTrackColor: AppColors.surface200,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: threshold,
              min: 50,
              max: 100,
              divisions: 50,
              onChanged: onThresholdChanged,
              onChangeEnd: onThresholdChangeEnd,
            ),
          ),
          AppButton.primary(
            label: 'Find Students',
            onTap: onLoad,
            icon: Icons.search_rounded,
          ),
        ],
      ),
    );
  }
}

class _BelowThresholdList extends StatelessWidget {
  const _BelowThresholdList({required this.response, required this.threshold});
  final dynamic response;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.errorRed, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  '${response.total} student(s) below ${threshold.toStringAsFixed(0)}%',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const _TableHeader(),
                  ...response.students.asMap().entries.map((entry) =>
                      _BelowThresholdRow(
                        student: entry.value,
                        index: entry.key + 1,
                        threshold: threshold,
                        isLast: entry.key == response.students.length - 1,
                      )),
                ],
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
            bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(
            flex: 3,
            child: Text('Admission No.',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey400, fontSize: 11)),
          ),
          Expanded(
            child: Text('Section',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey400, fontSize: 11)),
          ),
          Expanded(
            child: Text('Attendance',
                textAlign: TextAlign.end,
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey400, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _BelowThresholdRow extends StatelessWidget {
  const _BelowThresholdRow({
    required this.student,
    required this.index,
    required this.threshold,
    required this.isLast,
  });

  final dynamic student;
  final int index;
  final double threshold;
  final bool isLast;

  Color get _pctColor {
    final pct = student.overallPercentage as double;
    if (pct >= 75) return AppColors.warningAmber;
    if (pct >= 50) return AppColors.errorRed;
    return const Color(0xFF7F1D1D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$index',
                style: AppTypography.caption.copyWith(color: AppColors.grey400)),
          ),
          Expanded(
            flex: 3,
            child: Text(student.admissionNumber as String,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(
              student.section.isNotEmpty == true ? (student.section as String) : '—',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(student.overallPercentage as double).toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                      color: _pctColor, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.surface50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface200, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyMedium, width: 1.5)),
    );
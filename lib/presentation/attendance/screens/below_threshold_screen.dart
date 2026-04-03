import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
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
  ConsumerState<BelowThresholdScreen> createState() =>
      _BelowThresholdScreenState();
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Below Threshold', showBack: true),
      body: Column(
        children: [
          _buildFilterPanel(),
          const Divider(height: 1, color: AppColors.surface100),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class selector
          Builder(
            builder: (context) {
              final year = ref.watch(activeYearProvider);
              if (year == null) {
                return AppLoading.listTile();
              }
              _activeYearId = year.id;
              return ref.watch(standardsProvider(year.id)).when(
                    data: (standards) => DropdownButtonFormField<String>(
                      value: _selectedStandardId,
                      decoration: _dropdownDecoration('Select class'),
                      items: standards
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name,
                                    style: AppTypography.bodyMedium),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStandardId = val),
                    ),
                    loading: () => AppLoading.listTile(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
            },
          ),
          const SizedBox(height: AppDimensions.space16),

          // Threshold slider
          Row(
            children: [
              Text('Threshold: ',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.grey600)),
              Text(
                '${_threshold.toStringAsFixed(0)}%',
                style: AppTypography.titleSmall.copyWith(
                  color: _thresholdColor(_threshold),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _thresholdColor(_threshold),
              thumbColor: _thresholdColor(_threshold),
              overlayColor: _thresholdColor(_threshold).withOpacity(0.15),
              inactiveTrackColor: AppColors.surface200,
              trackHeight: 4,
            ),
            child: Slider(
              value: _threshold,
              min: 50,
              max: 100,
              divisions: 50,
              onChanged: (val) => setState(() => _threshold = val),
              onChangeEnd: (_) {
                if (_hasFetched) _load(); // reload on change if already fetched
              },
            ),
          ),

          AppButton.primary(label: 'Find Students', onTap: _load),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasFetched || _currentParams == null) {
      return const AppEmptyState(
        icon: Icons.warning_amber_outlined,
        title: 'Configure and search',
        subtitle:
            'Select a class, set the threshold, then tap Find Students.',
      );
    }

    final responseAsync = ref.watch(belowThresholdProvider(_currentParams!));

    return responseAsync.when(
      data: (response) {
        if (response.students.isEmpty) {
          return AppEmptyState(
            icon: Icons.check_circle_outline,
            title: 'All clear!',
            subtitle:
                'No students are below ${_threshold.toStringAsFixed(0)}% attendance.',
          );
        }
        return _BelowThresholdList(response: response, threshold: _threshold);
      },
      loading: () => AppLoading.fullPage(),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: _load,
      ),
    );
  }

  Color _thresholdColor(double t) {
    if (t >= 85) return AppColors.successGreen;
    if (t >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }
}

class _BelowThresholdList extends StatelessWidget {
  const _BelowThresholdList({required this.response, required this.threshold});
  final dynamic response; // BelowThresholdResponse
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(AppDimensions.space16),
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.errorRed, size: 20),
                const SizedBox(width: AppDimensions.space8),
                Text(
                  '${response.total} student(s) below ${threshold.toStringAsFixed(0)}%',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.errorRed),
                ),
              ],
            ),
          ),
        ),
        // Table header
        const SliverToBoxAdapter(child: _TableHeader()),
        // Students
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _BelowThresholdRow(
                student: response.students[index],
                index: index + 1,
                threshold: threshold,
                isLast: index == response.students.length - 1,
              ),
              childCount: response.students.length,
            ),
          ),
        ),
        const SliverPadding(
            padding: EdgeInsets.only(bottom: AppDimensions.space40)),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
      decoration: const BoxDecoration(
        color: AppColors.surface50,
        border: Border(
          bottom: BorderSide(color: AppColors.surface200, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28), // # column
          Expanded(
              flex: 3,
              child: Text('Admission No.',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.grey400))),
          Expanded(
              child: Text('Section',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.grey400))),
          Expanded(
            child: Text('Attendance',
                textAlign: TextAlign.end,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.grey400)),
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

  final dynamic student; // BelowThresholdStudent
  final int index;
  final double threshold;
  final bool isLast;

  Color get _pctColor {
    final pct = student.overallPercentage as double;
    if (pct >= 75) return AppColors.warningAmber;
    if (pct >= 50) return AppColors.errorRed;
    return const Color(0xFF7F1D1D); // deep red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: AppTypography.caption.copyWith(color: AppColors.grey400),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.admissionNumber as String,
              style: AppTypography.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              student.section.isNotEmpty == true
                  ? (student.section as String)
                  : '—',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    '${(student.overallPercentage as double).toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall
                        .copyWith(color: _pctColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _dropdownDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.surface50,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide:
              const BorderSide(color: AppColors.navyMedium, width: 1.5)),
    );

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_avatar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/profile_info_row.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userNotifierProvider.notifier).load());
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(userNotifierProvider.notifier)
          .uploadPhoto(File(picked.path));
      if (mounted) SnackbarUtils.showSuccess(context, 'Photo updated!');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to upload photo.');
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
    );
    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final userAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(title: 'Profile'),
      body: userAsync.when(
        loading: () => AppLoading.listView(count: 5),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.errorRed),
              const SizedBox(height: 16),
              Text(e.toString(), style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              AppButton.secondary(
                label: 'Retry',
                onTap: () =>
                    ref.read(userNotifierProvider.notifier).load(),
                fullWidth: false,
              ),
            ],
          ),
        ),
        data: (user) {
          final displayUser = user;
          final name = authUser?.email?.split('@').first ?? 'User';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.space24),

                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AppAvatar.xl(
                      imageUrl: displayUser?.profilePhotoUrl,
                      name: name,
                    ),
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.navyDeep,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 16, color: AppColors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space16),

                Text(
                  name.isNotEmpty
                      ? name[0].toUpperCase() + name.substring(1)
                      : 'User',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: AppDimensions.space4),

                if (authUser != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.navyLight.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      _roleLabel(authUser.role.backendValue),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.navyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: AppDimensions.space32),

                // Info rows
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16),
                  child: Column(
                    children: [
                      ProfileInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: displayUser?.email ??
                            authUser?.email ??
                            '—',
                      ),
                      const Divider(
                          height: 1, color: AppColors.surface100),
                      ProfileInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: displayUser?.phone ??
                            authUser?.phone ??
                            '—',
                      ),
                      const Divider(
                          height: 1, color: AppColors.surface100),
                      ProfileInfoRow(
                        icon: Icons.business_outlined,
                        label: 'School ID',
                        value: authUser?.schoolId ?? '—',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outlined,
                            color: AppColors.grey600),
                        title: Text('Change Password',
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.grey800)),
                        trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.grey400),
                        onTap: () =>
                            context.push(RouteNames.changePassword),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space32),

                AppButton.destructive(
                  label: 'Sign Out',
                  onTap: _logout,
                  icon: Icons.logout_rounded,
                ),

                const SizedBox(height: AppDimensions.space40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'SUPERADMIN':
        return 'Super Admin';
      case 'PRINCIPAL':
        return 'Principal';
      case 'TRUSTEE':
        return 'Trustee';
      case 'TEACHER':
        return 'Teacher';
      case 'STUDENT':
        return 'Student';
      case 'PARENT':
        return 'Parent';
      default:
        return role;
    }
  }
}
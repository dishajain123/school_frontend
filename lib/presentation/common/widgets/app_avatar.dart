import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

/// User photo display with initials fallback.
///
/// Sizes:
/// - `AppAvatar.sm` — 32px, compact lists
/// - `AppAvatar.md` — 40px, standard list tile (default)
/// - `AppAvatar.lg` — 56px, detail header
/// - `AppAvatar.xl` — 80px, profile screen (adds white ring)
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppDimensions.avatarMd,
    this.showRing = false,
    this.ringColor,
    this.backgroundColor,
    this.onTap,
  });

  factory AppAvatar.sm({
    Key? key,
    String? imageUrl,
    required String name,
    VoidCallback? onTap,
  }) =>
      AppAvatar(
        key: key,
        imageUrl: imageUrl,
        name: name,
        size: AppDimensions.avatarSm,
        onTap: onTap,
      );

  factory AppAvatar.md({
    Key? key,
    String? imageUrl,
    required String name,
    VoidCallback? onTap,
  }) =>
      AppAvatar(
        key: key,
        imageUrl: imageUrl,
        name: name,
        size: AppDimensions.avatarMd,
        onTap: onTap,
      );

  factory AppAvatar.lg({
    Key? key,
    String? imageUrl,
    required String name,
    VoidCallback? onTap,
  }) =>
      AppAvatar(
        key: key,
        imageUrl: imageUrl,
        name: name,
        size: AppDimensions.avatarLg,
        onTap: onTap,
      );

  factory AppAvatar.xl({
    Key? key,
    String? imageUrl,
    required String name,
    VoidCallback? onTap,
  }) =>
      AppAvatar(
        key: key,
        imageUrl: imageUrl,
        name: name,
        size: AppDimensions.avatarXl,
        showRing: true,
        onTap: onTap,
      );

  final String? imageUrl;
  final String name;
  final double size;

  /// Adds a 2px white border ring (used for profile size).
  final bool showRing;
  final Color? ringColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color get _bgColor {
    if (backgroundColor != null) return backgroundColor!;
    return AppColors.avatarBackground(name);
  }

  double get _fontSize => size * 0.38;

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (_, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
          backgroundColor: _bgColor,
        ),
        placeholder: (_, __) => _InitialsAvatar(
          initials: _initials,
          size: size,
          bgColor: _bgColor,
          fontSize: _fontSize,
        ),
        errorWidget: (_, __, ___) => _InitialsAvatar(
          initials: _initials,
          size: size,
          bgColor: _bgColor,
          fontSize: _fontSize,
        ),
      );
    } else {
      avatar = _InitialsAvatar(
        initials: _initials,
        size: size,
        bgColor: _bgColor,
        fontSize: _fontSize,
      );
    }

    if (showRing) {
      avatar = Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor ?? AppColors.white,
            width: 2,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return Semantics(
      label: name,
      child: avatar,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.initials,
    required this.size,
    required this.bgColor,
    required this.fontSize,
  });

  final String initials;
  final double size;
  final Color bgColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
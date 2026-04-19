import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/school_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = CurvedAnimation(
        parent: _logoController, curve: const Interval(0.0, 0.6));
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _loaderFade =
        CurvedAnimation(parent: _loaderController, curve: Curves.easeOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _loaderController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    await _initialize();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    await ref.read(authNotifierProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: -80,
                right: -60,
                child: _GlowCircle(size: 260, opacity: 0.06),
              ),
              const Positioned(
                bottom: -100,
                left: -80,
                child: _GlowCircle(size: 320, opacity: 0.05),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -40,
                child: const _GlowCircle(size: 180, opacity: 0.04),
              ),
              SafeArea(
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: _LogoMark(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              children: [
                                Text(
                                  'EduNest',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    fontSize: 36,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Smart School Platform',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.55),
                                    letterSpacing: 1.2,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        FadeTransition(
                          opacity: _loaderFade,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 56),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.goldPrimary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading your campus...',
                                  style: AppTypography.caption.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.45),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'v1.0.0',
                                  style: AppTypography.caption.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.25),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldPrimary, AppColors.goldDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Center(
        child: SchoolLogo(
          size: 60,
          borderRadius: 12,
          imagePadding: 6,
        ),
      ),
    );
  }
}

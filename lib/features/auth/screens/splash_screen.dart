import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 30, end: 80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Navigate after 2 seconds based on auth state
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      if (isLoggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Text(
                  'AURA',
                  style: GoogleFonts.poppins(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryAccent,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: AppTheme.primaryAccent.withAlpha(180),
                        blurRadius: _glowAnimation.value,
                      ),
                      Shadow(
                        color: AppTheme.primaryAccent.withAlpha(100),
                        blurRadius: _glowAnimation.value * 1.5,
                      ),
                      Shadow(
                        color: AppTheme.primaryAccent.withAlpha(60),
                        blurRadius: _glowAnimation.value * 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Dijital Yaşam Koçun',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

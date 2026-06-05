import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../features/social/providers/friends_provider.dart';
import '../../features/social/providers/social_providers.dart';

class BottomNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadActivityCount = ref.watch(unreadActivityCountProvider);
    final incomingRequestCount =
        ref.watch(friendRequestsProvider).valueOrNull?.length ?? 0;
    final socialNotificationCount = unreadActivityCount + incomingRequestCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: const Color(0xFF111111),
        selectedItemColor: AppTheme.primaryAccent,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded),
            label: 'Asistan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Tarama',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shield_rounded),
            label: 'Karakter',
          ),
          BottomNavigationBarItem(
            icon: Badge.count(
              count: socialNotificationCount,
              isLabelVisible: socialNotificationCount > 0,
              backgroundColor: AppTheme.primaryAccent,
              textColor: Colors.black,
              child: const Icon(Icons.people_rounded),
            ),
            label: 'Sosyal',
          ),
        ],
      ),
    );
  }
}

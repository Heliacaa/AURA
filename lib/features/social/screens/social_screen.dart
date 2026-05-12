import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'challenges_screen.dart';
import 'activity_feed_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Sekme değişimlerinde haptic feedback tetikleme
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        AppHaptics.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primaryAccent,
                labelColor: AppTheme.textWhite,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Akış'),
                  Tab(text: 'Meydan Okumalar'),
                  Tab(text: 'Sıralama'),
                  Tab(text: 'Arkadaşlar'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ActivityFeedScreen(),
                  ChallengesScreen(),
                  LeaderboardScreen(),
                  FriendsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

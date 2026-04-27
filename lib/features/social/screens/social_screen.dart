import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryAccent,
                labelColor: AppTheme.textWhite,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Sıralama'),
                  Tab(text: 'Arkadaşlar'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
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

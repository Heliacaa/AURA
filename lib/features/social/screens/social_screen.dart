import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../services/firestore_service.dart';
import '../providers/friends_provider.dart';
import '../providers/social_providers.dart';
import 'friends_screen.dart';
import 'leaderboard_screen.dart';
import 'challenges_screen.dart';
import 'activity_feed_screen.dart';

class SocialScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const SocialScreen({super.key, this.initialTab});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _markingFeedRead = false;
  bool _syncingMilestones = false;
  String? _lastSyncedMilestoneUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _indexForTab(widget.initialTab),
    );

    // Sekme değişimlerinde haptic feedback tetikleme
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        AppHaptics.lightImpact();
        if (_tabController.index == 0) {
          _markFeedRead();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMilestones();
      _markFeedRead();
    });
  }

  @override
  void didUpdateWidget(covariant SocialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _indexForTab(widget.initialTab);
    if (index != _tabController.index) {
      _tabController.animateTo(index);
    }
  }

  int _indexForTab(String? tab) {
    return switch (tab) {
      'challenges' => 1,
      'leaderboard' => 2,
      'friends' => 3,
      _ => 0,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markFeedRead() async {
    if (!mounted ||
        _tabController.index != 0 ||
        _markingFeedRead ||
        ref.read(unreadActivityCountProvider) == 0) {
      return;
    }

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    _markingFeedRead = true;
    try {
      await FirestoreService.instance.markSocialFeedRead(uid);
    } finally {
      _markingFeedRead = false;
    }
  }

  Future<void> _syncMilestones() async {
    if (_syncingMilestones) return;

    final uid = ref.read(currentUserIdProvider);
    if (uid == null || uid == _lastSyncedMilestoneUid) return;

    _syncingMilestones = true;
    try {
      await FirestoreService.instance.syncMilestoneActivities(uid);
      _lastSyncedMilestoneUid = uid;
    } finally {
      _syncingMilestones = false;
    }
  }

  Widget _tabLabel(String label, int count) {
    if (count == 0) return Text(label);
    return Badge.count(
      count: count,
      backgroundColor: AppTheme.primaryAccent,
      textColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadActivityCount = ref.watch(unreadActivityCountProvider);
    final incomingRequestCount =
        ref.watch(friendRequestsProvider).valueOrNull?.length ?? 0;

    ref.listen(activitiesProvider, (previous, next) {
      if (next.hasValue && _tabController.index == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _markFeedRead());
      }
    });
    ref.listen(currentUserIdProvider, (previous, next) {
      if (next != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncMilestones());
      }
    });

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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(child: _tabLabel('Akış', unreadActivityCount)),
                  const Tab(text: 'Meydan Okumalar'),
                  const Tab(text: 'Sıralama'),
                  Tab(child: _tabLabel('Arkadaşlar', incomingRequestCount)),
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

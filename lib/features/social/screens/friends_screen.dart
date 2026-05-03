import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/aura_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../../../services/firestore_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _emailController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddFriend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _searching = true);

    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      final authUser = ref.read(authStateProvider).valueOrNull;
      if (currentUser == null || authUser == null) return;

      final foundUser = await FirestoreService.instance.findUserByEmail(email);
      if (foundUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kullanıcı bulunamadı')));
        }
        return;
      }

      if (foundUser.uid == authUser.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kendinizi ekleyemezsiniz')),
          );
        }
        return;
      }

      await FirestoreService.instance.sendFriendRequest(
        fromUid: authUser.uid,
        fromName: currentUser.displayName,
        fromEmail: currentUser.email,
        toUid: foundUser.uid,
        toName: foundUser.displayName,
        toEmail: foundUser.email,
      );

      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık isteği gönderildi! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arkadaşlar',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 20),

            // Add friend section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: GoogleFonts.poppins(color: AppTheme.textWhite),
                    decoration: AppTheme.inputDecoration(
                      hintText: 'E-posta ile ara',
                      prefixIcon: Icons.search,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _searching ? null : _searchAndAddFriend,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _searching
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Icon(Icons.person_add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Friend requests
            requestsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arkadaşlık İstekleri',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...requests.map(
                      (req) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.cardDecoration(
                          borderColor: AppTheme.warningOrange,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryAccent,
                              radius: 18,
                              child: Text(
                                req.friendName.isNotEmpty
                                    ? req.friendName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.friendName,
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    req.friendEmail,
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: AppTheme.secondaryAccent,
                              ),
                              onPressed: () async {
                                if (authUser != null) {
                                  await FirestoreService.instance
                                      .acceptFriendRequest(
                                        authUser.uid,
                                        req.friendUid,
                                      );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: AppTheme.statRed,
                              ),
                              onPressed: () async {
                                if (authUser != null) {
                                  await FirestoreService.instance.removeFriend(
                                    authUser.uid,
                                    req.friendUid,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Friends list
            Text(
              'Arkadaşlarım',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            friendsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryAccent),
              ),
              error: (e, _) => Text(
                'Hata: $e',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
              data: (friends) {
                if (friends.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
                    ),
                    child: Text(
                      'Henüz arkadaş yok. Birilerini ekle!',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return Column(
                  children: friends
                      .map(
                        (f) => AuraCard(
                          emoji: '👤',
                          title: f.friendName,
                          subtitle: f.friendEmail,
                          borderColor: AppTheme.primaryAccent,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

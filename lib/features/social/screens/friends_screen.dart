import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/public_profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/friends_provider.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Arkadaşlar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: const FriendsScreen(showTitle: false),
    );
  }
}

class FriendsScreen extends ConsumerStatefulWidget {
  final bool showTitle;

  const FriendsScreen({super.key, this.showTitle = true});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _emailController = TextEditingController();
  bool _searching = false;
  bool _acting = false;
  PublicProfileModel? _searchResult;
  String? _searchMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _searchResult = null;
        _searchMessage = 'Geçerli bir e-posta adresi gir.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchResult = null;
      _searchMessage = null;
    });

    try {
      final result = await ref
          .read(friendServiceProvider)
          .searchUserByEmail(email);
      if (!mounted) return;
      setState(() {
        _searchResult = result;
        _searchMessage = result == null ? 'Kullanıcı bulunamadı.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchMessage = 'Arama başarısız: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _acting = true);
    try {
      await action();
      ref.invalidate(friendshipsProvider);
      if (_searchResult != null) {
        ref.invalidate(publicProfileProvider(_searchResult!.uid));
        try {
          _searchResult = await ref
              .read(friendServiceProvider)
              .getPublicProfile(_searchResult!.uid);
        } catch (_) {
          _searchResult = null;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _removeFriendWithConfirmation(
    String uid,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Arkadaşı kaldır?',
          style: GoogleFonts.poppins(
            color: AppTheme.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '$displayName arkadaş listenden kaldırılacak. Emin misin?',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Kaldır',
              style: GoogleFonts.poppins(color: AppTheme.statRed),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    await _runAction(
      () => ref.read(friendServiceProvider).removeFriend(uid),
      successMessage: 'Arkadaş kaldırıldı.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final incomingAsync = ref.watch(friendRequestsProvider);
    final outgoingAsync = ref.watch(sentFriendRequestsProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final currentUid = authUser?.uid ?? '';

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: () async {
          ref.invalidate(friendshipsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 250));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            if (widget.showTitle) ...[
              Text(
                'Arkadaşlar',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _SearchBox(
              controller: _emailController,
              searching: _searching,
              onSearch: _searchByEmail,
            ),
            if (_searchMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _searchMessage!,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (_searchResult != null) ...[
              const SizedBox(height: 12),
              _SearchResultCard(
                profile: _searchResult!,
                busy: _acting,
                onOpenProfile: () =>
                    context.push('/public-profile/${_searchResult!.uid}'),
                onSendRequest: () => _runAction(
                  () => ref
                      .read(friendServiceProvider)
                      .sendFriendRequest(_searchResult!.uid),
                  successMessage: 'Arkadaşlık isteği gönderildi.',
                ),
                onAccept: () => _runAction(
                  () => ref
                      .read(friendServiceProvider)
                      .acceptFriendRequest(_searchResult!.uid),
                  successMessage: 'Arkadaşlık isteği kabul edildi.',
                ),
              ),
            ],
            const SizedBox(height: 24),
            _RequestSection(
              title: 'Gelen İstekler',
              emptyText: 'Gelen arkadaşlık isteği yok.',
              asyncValue: incomingAsync,
              currentUid: currentUid,
              actionsBuilder: (friendship) => [
                IconButton(
                  tooltip: 'Kabul et',
                  icon: const Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryAccent,
                  ),
                  onPressed: _acting
                      ? null
                      : () => _runAction(
                          () => ref
                              .read(friendServiceProvider)
                              .acceptFriendRequest(
                                friendship.otherUid(currentUid),
                              ),
                          successMessage: 'Arkadaşlık isteği kabul edildi.',
                        ),
                ),
                IconButton(
                  tooltip: 'Reddet',
                  icon: const Icon(Icons.cancel, color: AppTheme.statRed),
                  onPressed: _acting
                      ? null
                      : () => _runAction(
                          () => ref
                              .read(friendServiceProvider)
                              .declineFriendRequest(
                                friendship.otherUid(currentUid),
                              ),
                          successMessage: 'Arkadaşlık isteği reddedildi.',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _RequestSection(
              title: 'Gönderilen İstekler',
              emptyText: 'Bekleyen gönderilmiş istek yok.',
              asyncValue: outgoingAsync,
              currentUid: currentUid,
              actionsBuilder: (friendship) => [
                IconButton(
                  tooltip: 'İptal et',
                  icon: const Icon(
                    Icons.cancel_schedule_send_rounded,
                    color: AppTheme.warningOrange,
                  ),
                  onPressed: _acting
                      ? null
                      : () => _runAction(
                          () => ref
                              .read(friendServiceProvider)
                              .declineFriendRequest(
                                friendship.otherUid(currentUid),
                              ),
                          successMessage: 'Arkadaşlık isteği iptal edildi.',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _FriendsListSection(
              asyncValue: friendsAsync,
              currentUid: currentUid,
              acting: _acting,
              onOpenProfile: (uid) => context.push('/public-profile/$uid'),
              onRemove: _removeFriendWithConfirmation,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final VoidCallback onSearch;

  const _SearchBox({
    required this.controller,
    required this.searching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            style: GoogleFonts.poppins(color: AppTheme.textWhite),
            decoration: AppTheme.inputDecoration(
              hintText: 'E-posta ile ara',
              prefixIcon: Icons.search,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: searching ? null : onSearch,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryAccent,
            fixedSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: searching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.search_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final PublicProfileModel profile;
  final bool busy;
  final VoidCallback onOpenProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onAccept;

  const _SearchResultCard({
    required this.profile,
    required this.busy,
    required this.onOpenProfile,
    required this.onSendRequest,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final safeName = profile.displayName.isNotEmpty
        ? profile.displayName
        : 'AURA User';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(
        borderColor: AppTheme.secondaryAccent,
      ),
      child: Row(
        children: [
          _Avatar(name: safeName, avatarUrl: profile.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onOpenProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safeName,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    profile.email.isNotEmpty
                        ? profile.email
                        : 'Level ${profile.currentLevel}',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SearchActionButton(
            profile: profile,
            busy: busy,
            onSendRequest: onSendRequest,
            onAccept: onAccept,
          ),
        ],
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  final PublicProfileModel profile;
  final bool busy;
  final VoidCallback onSendRequest;
  final VoidCallback onAccept;

  const _SearchActionButton({
    required this.profile,
    required this.busy,
    required this.onSendRequest,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (profile.isSelf) {
      return const Icon(Icons.person_rounded, color: AppTheme.textSecondary);
    }
    if (profile.isFriend) {
      return const Icon(Icons.check_circle, color: AppTheme.secondaryAccent);
    }
    if (profile.isIncomingRequest) {
      return IconButton(
        tooltip: 'Kabul et',
        onPressed: busy ? null : onAccept,
        icon: const Icon(Icons.check_circle, color: AppTheme.secondaryAccent),
      );
    }
    if (profile.isOutgoingRequest) {
      return const Icon(Icons.schedule_rounded, color: AppTheme.warningOrange);
    }
    return IconButton(
      tooltip: 'Arkadaşlık isteği gönder',
      onPressed: busy ? null : onSendRequest,
      icon: const Icon(Icons.person_add_rounded, color: AppTheme.primaryAccent),
    );
  }
}

class _RequestSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final AsyncValue<List<FriendshipModel>> asyncValue;
  final String currentUid;
  final List<Widget> Function(FriendshipModel friendship) actionsBuilder;

  const _RequestSection({
    required this.title,
    required this.emptyText,
    required this.asyncValue,
    required this.currentUid,
    required this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: asyncValue.when(
        loading: () => const SizedBox(height: 36),
        error: (e, _) => Text(
          'Hata: $e',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyBox(text: emptyText);
          return Column(
            children: items
                .map(
                  (friendship) => _FriendshipTile(
                    friendship: friendship,
                    currentUid: currentUid,
                    onTap: () => context.push(
                      '/public-profile/${friendship.otherUid(currentUid)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actionsBuilder(friendship),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _FriendsListSection extends StatelessWidget {
  final AsyncValue<List<FriendshipModel>> asyncValue;
  final String currentUid;
  final bool acting;
  final ValueChanged<String> onOpenProfile;
  final void Function(String uid, String displayName) onRemove;

  const _FriendsListSection({
    required this.asyncValue,
    required this.currentUid,
    required this.acting,
    required this.onOpenProfile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Arkadaşlarım',
      child: asyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
        ),
        error: (e, _) => Text(
          'Hata: $e',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        data: (friends) {
          if (friends.isEmpty) {
            return const _EmptyBox(text: 'Henüz arkadaş yok. Birilerini ekle!');
          }
          return Column(
            children: friends.map((friendship) {
              final uid = friendship.otherUid(currentUid);
              final friend = friendship.otherUser(currentUid);
              final displayName = friend.displayName.isNotEmpty
                  ? friend.displayName
                  : 'AURA User';
              return _FriendshipTile(
                friendship: friendship,
                currentUid: currentUid,
                onTap: () => onOpenProfile(uid),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Profili aç',
                      onPressed: () => onOpenProfile(uid),
                      icon: const Icon(
                        Icons.person_search_rounded,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kaldır',
                      onPressed: acting
                          ? null
                          : () => onRemove(uid, displayName),
                      icon: const Icon(
                        Icons.person_remove_rounded,
                        color: AppTheme.statRed,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FriendshipTile extends StatelessWidget {
  final FriendshipModel friendship;
  final String currentUid;
  final VoidCallback onTap;
  final Widget trailing;

  const _FriendshipTile({
    required this.friendship,
    required this.currentUid,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final friend = friendship.otherUser(currentUid);
    final safeName = friend.displayName.isNotEmpty
        ? friend.displayName
        : 'AURA User';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            _Avatar(name: safeName, avatarUrl: friend.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safeName,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    friend.email,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _Avatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppTheme.primaryAccent.withAlpha(70),
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      radius: 20,
      child: avatarUrl.isEmpty
          ? Text(
              name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

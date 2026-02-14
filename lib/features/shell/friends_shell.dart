import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../home/home_screen.dart';
import '../reels/reels_screen.dart';
import '../post/create_post_screen.dart';
import '../chat/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/chat_service.dart';

class FriendsShell extends StatefulWidget {
  const FriendsShell({super.key});

  @override
  State<FriendsShell> createState() => _FriendsShellState();
}

class _FriendsShellState extends State<FriendsShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ReelsScreen(),
    CreatePostScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<int>(
      stream: user == null
          ? Stream<int>.value(0)
          : ChatService.instance.watchUnreadChatCount(uid: user.uid),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            elevation: 10,
            backgroundColor: theme.colorScheme.surface,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor:
                theme.colorScheme.onSurface.withOpacity(0.6),
            showUnselectedLabels: false,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(PhosphorIconsLight.houseSimple),
                activeIcon: Icon(PhosphorIconsBold.houseSimple),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(PhosphorIconsLight.playCircle),
                activeIcon: Icon(PhosphorIconsBold.playCircle),
                label: 'Reels',
              ),
              const BottomNavigationBarItem(
                icon: Icon(PhosphorIconsLight.squaresFour),
                activeIcon: Icon(PhosphorIconsBold.squaresFour),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: _MessagesIcon(
                  unreadCount: unread,
                  isActive: false,
                ),
                activeIcon: _MessagesIcon(
                  unreadCount: unread,
                  isActive: true,
                ),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(PhosphorIconsLight.userCircle),
                activeIcon: Icon(PhosphorIconsBold.userCircle),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessagesIcon extends StatelessWidget {
  final int unreadCount;
  final bool isActive;

  const _MessagesIcon({
    required this.unreadCount,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final baseIcon = isActive
        ? const Icon(PhosphorIconsBold.chatCircle)
        : const Icon(PhosphorIconsLight.chatCircle);

    if (unreadCount <= 0) {
      return baseIcon;
    }

    final display = unreadCount > 9 ? '9+' : '$unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              display,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

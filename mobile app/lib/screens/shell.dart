import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/bottom_nav.dart';
import 's09_search.dart';
import 's11_home.dart';
import 's21_profile.dart';
import 'supporting.dart';

/// Tab shell for the visitor experience: Home / Search / Saved / Community /
/// Profile. Uses an IndexedStack so each tab keeps its scroll position and
/// state when switching, exactly like the real app would.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex.clamp(0, visitorNav.length - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenSearch: () => setState(() => _index = 1)),
            const SearchScreen(embedded: true),
            const SavedScreen(),
            const CommunityScreen(embedded: true),
            const ProfileScreen(embedded: true),
          ],
        ),
      ),
      backgroundColor: RC.bg,
      bottomNavigationBar: ResivynBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

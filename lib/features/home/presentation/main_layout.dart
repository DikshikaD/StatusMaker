import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/theme/theme_controller.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/home/presentation/home_screen.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/create/presentation/create_screen.dart';
import 'package:status_maker/features/favorites/presentation/favorites_screen.dart';
import 'package:status_maker/features/settings/presentation/settings_screen.dart';
import 'package:status_maker/core/utils/app_navigation.dart';
import 'package:status_maker/core/utils/responsive.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  const _NavItem(this.icon, this.activeIcon, this.labelKey);
}

class _MainLayoutState extends State<MainLayout> {
  // The selected tab lives in a notifier rather than plain state so switching
  // tabs rebuilds only the IndexedStack and the nav bar — NOT the five tab
  // widgets. setState here would recreate all of them on every tap, which on
  // the heavier tabs (the Search tab paints a lot) is most of the cost of a
  // switch. See [build] for how the children are kept identical.
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  // Bumped each time the Home tab is (re)selected so its feed auto-refreshes.
  final ValueNotifier<int> _homeTick = ValueNotifier<int>(0);

  // Bumped when Favorites should jump to "My Creations" and reload it — e.g.
  // right after the user saves a status.
  final ValueNotifier<int> _creationsTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    AppNav.request.addListener(_onNavRequest);
  }

  @override
  void dispose() {
    AppNav.request.removeListener(_onNavRequest);
    _index.dispose();
    _homeTick.dispose();
    _creationsTick.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    _index.value = index;
    // Re-selecting Home refreshes its feed, even if it was already showing.
    if (index == 0) _homeTick.value++;
  }

  /// A screen pushed above the shell (an editor) has finished and asked to send
  /// the user somewhere. Close everything stacked on top of the shell, then
  /// switch tabs and refresh whatever the destination shows.
  void _onNavRequest() {
    final req = AppNav.request.value;
    if (req == null || !mounted) return;
    AppNav.request.value = null;

    // Switch first, then pop: the destination is already in place behind the
    // editor, so it's revealed by the editor's own slide-out rather than
    // appearing after it.
    _goToTab(req.index);
    if (req.showCreations) _creationsTick.value++;

    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppNav.shellRouteName || route.isFirst,
    );
  }

  // Built fresh on every build (see [build]) so that a theme or language change
  // recreates the tab widgets and they repaint with the new palette. Using a
  // cached/const list would keep the old colors on inactive tabs.
  List<Widget> get _pages => [
        // Intentionally NOT const: const instances are canonicalized to the same
        // object, so IndexedStack would skip rebuilding them and inactive tabs
        // would keep the old theme colors.
        HomeScreen(refreshSignal: _homeTick),
        ExploreScreen(),
        CreateScreen(),
        FavoritesScreen(showCreationsSignal: _creationsTick),
        SettingsScreen(),
      ];

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'nav_home'),
    _NavItem(Icons.search_outlined, Icons.search_rounded, 'nav_explore'),
    _NavItem(Icons.add_circle_outline, Icons.add_circle_rounded, 'nav_create'),
    _NavItem(Icons.favorite_outline, Icons.favorite_rounded, 'nav_favorites'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'nav_settings'),
  ];

  @override
  Widget build(BuildContext context) {
    // MainLayout is a pushed route, so a MaterialApp rebuild won't reach it.
    // Listen to theme + language directly so every tab repaints on change.
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeController.mode, S.lang]),
      builder: (context, _) {
        // Built once here and reused for every tab switch. Because the
        // IndexedStack below is handed the *same* widget instances each time
        // the index changes, Flutter short-circuits the update and no tab's
        // content is rebuilt — only which one is shown changes. A new list is
        // created solely when the theme or language changes, which is exactly
        // when the tabs do need to be recreated to pick up the new palette.
        final pages = _pages;
        return Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: _index,
            builder: (context, index, __) =>
                IndexedStack(index: index, children: pages),
          ),
          bottomNavigationBar: ValueListenableBuilder<int>(
            valueListenable: _index,
            builder: (context, index, __) => _buildNav(index),
          ),
        );
      },
    );
  }

  Widget _buildNav(int current) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (i) => _navItem(i, _items[i], current),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, _NavItem item, int current) {
    final selected = index == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _goToTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16.w : 12.w,
          vertical: 10.h,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon gently scales & swaps when selected.
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: selected ? AppColors.accent : AppColors.textSecondary,
                size: 24.w,
              ),
            ),
            // Label slides in only for the selected item.
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Text(
                        S.t(item.labelKey),
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

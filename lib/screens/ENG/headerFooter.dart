
import 'package:flutter/material.dart';
import '../../components/sirvya_logo.dart';
import '../../constants/app_colors.dart';
import '../../theme/fitlek_theme_extension.dart';


class AppHeader extends StatelessWidget {
  final String? firstName;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final String? title;
  final double scrollOffset;

  const AppHeader({
    super.key,
    this.firstName,
    this.avatarUrl,
    this.onAvatarTap,
    this.onNotificationTap,
    this.showBackButton = false,
    this.onBackTap,
    this.title,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final f = context.fitlek;
    final isScrolled = scrollOffset > 50;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(20, 12, 20, isScrolled ? 12 : 16),
      decoration: BoxDecoration(
        color: isScrolled ? f.card.withValues(alpha: 0.95) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isScrolled
                ? f.border.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: f.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton)
              _buildBackButton(context)
            else
              _buildLogo(context),
            const Spacer(),
            if (title != null && isScrolled)
              Expanded(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            if (title != null && isScrolled) const Spacer(),
            if (onNotificationTap != null) _buildNotificationBell(context),
            const SizedBox(width: 12),
            _buildAvatar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    return GestureDetector(
      onTap: onBackTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: f.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: f.border, width: 1),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface, size: 16),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return const SirvyaLogo(variant: SirvyaLogoVariant.wordmark, height: 28);
  }

  Widget _buildNotificationBell(BuildContext context) {
    final f = context.fitlek;

    return GestureDetector(
      onTap: onNotificationTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: f.card2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: f.border, width: 1),
            ),
            child: Icon(Icons.notifications_outlined,
                color: f.textSecondary, size: 20),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: f.card2,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
                  firstName != null && firstName!.isNotEmpty
                      ? firstName![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  APP FOOTER — Bottom Navigation
// ═════════════════════════════════════════════

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final f = context.fitlek;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: f.border.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: f.shadow,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? cs.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active ? cs.primary : f.navUnselected,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? cs.primary : f.navUnselected,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ═════════════════════════════════════════════
//  MAIN SCREEN — Assemble Header + Body + Footer
// ═════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final String? firstName;
  final String? avatarUrl;
  final VoidCallback? onLogout;

  const MainScreen({
    super.key,
    required this.clientID,
    required this.token,
    this.firstName,
    this.avatarUrl,
    this.onLogout,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  late final List<Widget> _screens;

  static const _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
    ),
    NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Sessions',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      setState(() => _scrollOffset = _scrollCtrl.offset);
    });

    _screens = [
      _HomePlaceholder(),
      _ExplorePlaceholder(),
      _SessionsPlaceholder(),
      _ProfilePlaceholder(),
    ];
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _onAvatarTap() => setState(() => _currentIndex = 3);

  void _onNotificationTap() => debugPrint('Notifications tapped');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          AppHeader(
            firstName: widget.firstName,
            avatarUrl: widget.avatarUrl,
            onAvatarTap: _onAvatarTap,
            onNotificationTap: _onNotificationTap,
            scrollOffset: _scrollOffset,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final f = context.fitlek;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 20,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Home Content $i',
            style: TextStyle(color: f.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ExplorePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Explore',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _SessionsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sessions',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
        ),
      ),
    );
  }
}

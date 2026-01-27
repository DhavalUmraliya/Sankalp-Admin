import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dashboard/dashboard_page.dart';
import '../notifications/notification_sender_page.dart';
import '../users/users_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  late final _navItems = <_NavItem>[
    const _NavItem(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    const _NavItem(
      label: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    const _NavItem(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    const _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pages = <Widget>[
      const DashboardPage(),
      const UsersPage(),
      const NotificationSenderPage(),
      const _SettingsPage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useDrawer = width < 900;
        final railExtended = width >= 1200;

        final sidebar = NavigationRail(
          extended: railExtended,
          minExtendedWidth: 260,
          backgroundColor: cs.surfaceContainerLowest,
          indicatorColor: cs.secondaryContainer,
          selectedIconTheme: IconThemeData(color: cs.onSecondaryContainer),
          selectedLabelTextStyle: TextStyle(
            color: cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
          unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
          unselectedLabelTextStyle: TextStyle(color: cs.onSurfaceVariant),
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _BrandHeader(extended: railExtended),
          ),
          destinations: [
            for (final item in _navItems)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        );

        return Scaffold(
          drawer: useDrawer
              ? Drawer(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _BrandHeader(extended: true),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _navItems.length,
                            itemBuilder: (context, i) {
                              final item = _navItems[i];
                              final selected = i == _selectedIndex;
                              return ListTile(
                                leading: Icon(
                                  selected ? item.selectedIcon : item.icon,
                                ),
                                title: Text(item.label),
                                selected: selected,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  setState(() => _selectedIndex = i);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          appBar: AppBar(
            title: Text(_navItems[_selectedIndex].label),
            centerTitle: false,
            actions: [
              if (!useDrawer)
                SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _SearchField(
                      hintText: 'Search…',
                      onSubmitted: (_) {},
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<void>(
                tooltip: 'Account',
                itemBuilder: (context) => [
                  const PopupMenuItem<void>(
                    enabled: false,
                    child: _AccountHeader(),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<void>(
                    onTap: () => FirebaseAuth.instance.signOut(),
                    child: const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Sign out'),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, color: cs.onPrimaryContainer),
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (!useDrawer) sidebar,
              Expanded(
                child: ColoredBox(
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ContentCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(_selectedIndex),
                          child: pages[_selectedIndex],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.spa, color: cs.onPrimaryContainer, size: 18),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sankalp Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Control center',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText, required this.onSubmitted});

  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    return Row(
      children: [
        const CircleAvatar(radius: 16, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Signed in as'),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Expanded(child: Center(child: Text('Settings page placeholder'))),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../config/theme.dart';

class NavigationDestinationItem {
  const NavigationDestinationItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

Future<void> showNavigationMenuPanel(
  BuildContext context, {
  required String currentRoute,
}) {
  const destinations = <NavigationDestinationItem>[
    NavigationDestinationItem(
      label: 'Carte',
      icon: Icons.location_on_outlined,
      route: '/home',
    ),
    NavigationDestinationItem(
      label: 'Liste',
      icon: Icons.list_alt_outlined,
      route: '/list',
    ),
    NavigationDestinationItem(
      label: 'Historique',
      icon: Icons.history,
      route: '/history',
    ),
    NavigationDestinationItem(
      label: 'Profil',
      icon: Icons.person_outline,
      route: '/profile',
    ),
  ];

  final mediaQuery = MediaQuery.of(context);
  final panelTopOffset = mediaQuery.padding.top + kToolbarHeight;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le menu',
    barrierColor: Colors.black26,
    pageBuilder: (dialogContext, _, __) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned(
              top: panelTopOffset,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < destinations.length; index++) ...[
                        _NavigationPanelAction(
                          item: destinations[index],
                          isActive: currentRoute == destinations[index].route,
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            if (currentRoute == destinations[index].route) {
                              return;
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) {
                                return;
                              }

                              Navigator.pushReplacementNamed(
                                context,
                                destinations[index].route,
                              );
                            });
                          },
                        ),
                        if (index != destinations.length - 1)
                          const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (dialogContext, animation, _, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

class _NavigationPanelAction extends StatelessWidget {
  const _NavigationPanelAction({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavigationDestinationItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

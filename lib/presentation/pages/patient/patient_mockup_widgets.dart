import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

const patientBg = Color(0xFFF7F9F9);
const patientText = Color(0xFF1E2224);
const patientMuted = Color(0xFF6F777A);
const patientTeal = Color(0xFF00565A);
const patientTeal2 = Color(0xFF0D6F73);
const patientMint = Color(0xFF6DEFD6);
const patientMintSoft = Color(0xFFE9FFFA);
const patientBorder = Color(0xFFDDE3E3);
const patientDanger = Color(0xFFC5161D);
const patientDangerSoft = Color(0xFFFFDAD7);
const patientNeutral = Color(0xFFE6EAEA);

class PatientMockScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final bool extendBody;

  const PatientMockScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.appBar,
    this.backgroundColor = patientBg,
    this.extendBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      extendBody: extendBody,
      body: child,
      bottomNavigationBar: PatientBottomNav(currentIndex: currentIndex),
    );
  }
}

class PatientBottomNav extends StatelessWidget {
  final int currentIndex;

  const PatientBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_rounded, 'Home', AppRoutes.patientDashboard),
      _NavItem(Icons.auto_graph_rounded, 'Progress', AppRoutes.treatment),
      _NavItem(
        Icons.calendar_month_rounded,
        'Reminders',
        AppRoutes.reminders,
      ),
      _NavItem(
        Icons.smart_toy_outlined,
        'Chatbot',
        AppRoutes.chatbot,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final active = index == currentIndex;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(item.route),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: active ? patientMintSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active ? patientTeal : const Color(0xFF9AAAC0),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: active ? patientTeal : const Color(0xFF8FA0B7),
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem(this.icon, this.label, this.route);
}

class PatientTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData leadingIcon;
  final bool showBack;
  final VoidCallback? onLeadingTap;
  final List<Widget>? actions;

  const PatientTopBar({
    super.key,
    required this.title,
    this.leadingIcon = Icons.person,
    this.showBack = false,
    this.onLeadingTap,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: patientTeal,
      toolbarHeight: 66,
      leadingWidth: 70,
      leading: showBack
          ? IconButton(
              onPressed: onLeadingTap ?? () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF5D6A80)),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 26),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onLeadingTap,
                child: PatientAvatar(icon: leadingIcon, radius: 20),
              ),
            ),
      titleSpacing: showBack ? 0 : 10,
      title: Text(
        title,
        style: const TextStyle(
          color: patientTeal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      actions: actions ??
          [
            IconButton(
              onPressed: () => context.go(AppRoutes.patientNotifications),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 10),
          ],
    );
  }
}

class PatientAvatar extends StatelessWidget {
  final IconData icon;
  final double radius;
  final Color color;

  const PatientAvatar({
    super.key,
    this.icon = Icons.person,
    this.radius = 18,
    this.color = patientTeal2,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: radius),
    );
  }
}

class PatientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  const PatientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
    this.borderColor = patientBorder,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PatientChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const PatientChip({
    super.key,
    required this.label,
    this.color = patientMintSoft,
    this.textColor = patientTeal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: patientText,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

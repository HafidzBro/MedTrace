import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

const doctorBg = Color(0xFFF7F9F9);
const doctorText = Color(0xFF1E2224);
const doctorMuted = Color(0xFF6F777A);
const doctorTeal = Color(0xFF00565A);
const doctorTeal2 = Color(0xFF0D6F73);
const doctorMint = Color(0xFF6DEFD6);
const doctorMintSoft = Color(0xFFE9FFFA);
const doctorBorder = Color(0xFFDDE3E3);
const doctorDanger = Color(0xFFC5161D);
const doctorDangerSoft = Color(0xFFFFDAD7);
const doctorWarningSoft = Color(0xFFFFE8D8);
const doctorNeutral = Color(0xFFE6EAEA);

class DoctorMockScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;
  final bool extendBody;

  const DoctorMockScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.appBar,
    this.backgroundColor = doctorBg,
    this.extendBody = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      extendBody: extendBody,
      body: child,
      bottomNavigationBar: DoctorBottomNav(currentIndex: currentIndex),
    );
  }
}

class DoctorBottomNav extends StatelessWidget {
  final int currentIndex;

  const DoctorBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.grid_view_rounded, 'Dashboard', AppRoutes.doctorDashboard),
      _NavItem(
          Icons.people_alt_rounded, 'Patients', AppRoutes.patientManagement),
      _NavItem(Icons.map_outlined, 'Map', AppRoutes.doctorMap),
      _NavItem(Icons.warning_amber_rounded, 'Alerts', AppRoutes.alerts),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    color: active ? doctorMintSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            size: 23,
                            color:
                                active ? doctorTeal : const Color(0xFF9AA3AA),
                          ),
                          if (item.label == 'Alerts' && active)
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: doctorDanger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? doctorTeal : const Color(0xFF8FA0B7),
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          height: 1,
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

class DoctorTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData leadingIcon;
  final bool centeredTitle;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onLeadingTap;

  const DoctorTopBar({
    super.key,
    this.title = 'MedTrace',
    this.leadingIcon = Icons.person,
    this.centeredTitle = false,
    this.showBack = false,
    this.actions,
    this.onLeadingTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: doctorTeal,
      toolbarHeight: 66,
      centerTitle: centeredTitle,
      leadingWidth: showBack ? 52 : 72,
      leading: showBack
          ? IconButton(
              onPressed: onLeadingTap ?? () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: doctorText),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 28),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap:
                    onLeadingTap ?? () => context.go(AppRoutes.doctorProfile),
                child: DoctorAvatar(icon: leadingIcon, radius: 21),
              ),
            ),
      titleSpacing: showBack ? 0 : 10,
      title: Text(
        title,
        style: const TextStyle(
          color: doctorTeal,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      actions: actions ??
          [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                Positioned(
                  right: 13,
                  top: 18,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: doctorDanger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
    );
  }
}

class DoctorAvatar extends StatelessWidget {
  final IconData icon;
  final double radius;
  final Color color;
  final String? initials;

  const DoctorAvatar({
    super.key,
    this.icon = Icons.person,
    this.radius = 20,
    this.color = doctorTeal2,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: initials == null
          ? Icon(icon, color: Colors.white, size: radius)
          : Text(
              initials!,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.78,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  const DoctorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
    this.borderColor = doctorBorder,
    this.radius = 10,
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

class DoctorChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const DoctorChip({
    super.key,
    required this.label,
    this.color = doctorMintSoft,
    this.textColor = doctorTeal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorSectionTitle extends StatelessWidget {
  final String text;

  const DoctorSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: doctorText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

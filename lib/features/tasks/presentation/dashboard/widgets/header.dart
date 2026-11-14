// App bar: date + greeting, Morning Review sunrise pill, avatar.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../task_setup/motion.dart';
import '../../task_setup/pages/review_page.dart' show FluidToggle;
import '../dash_theme.dart';
import '../dashboard_store.dart';

class DashHeader extends StatelessWidget {
  const DashHeader({
    super.key,
    required this.store,
    required this.onReview,
    this.userInitials = 'AB',
    this.userAvatarUrl,
    this.onSignOut,
  });

  final DashboardStore store;
  final VoidCallback onReview;
  final String userInitials;
  final String? userAvatarUrl;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final reviewCount = store.toReview.length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerDate(DateTime.now()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: p.textFaint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today\'s focus',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: p.text,
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: Motion.ms(250),
          transitionBuilder: (c, a) => ScaleTransition(
            scale: CurvedAnimation(parent: a, curve: Motion.spring),
            child: FadeTransition(opacity: a, child: c),
          ),
          child: reviewCount > 0
              ? ReviewPill(
                  key: const ValueKey('review'),
                  count: reviewCount,
                  onTap: onReview)
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => showProfileSheet(
            context,
            store,
            userInitials,
            onSignOut,
            avatarUrl: userAvatarUrl,
          ),
          child: DashAvatar(
            initials: userInitials,
            avatarUrl: userAvatarUrl,
          ),
        ),
      ],
    );
  }
}

class DashAvatar extends StatelessWidget {
  const DashAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 38,
  });

  final String initials;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DashPalette.emerald.withAlpha(36),
        border: Border.all(color: p.border),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: DashPalette.emerald,
        ),
      ),
    );

    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return fallback;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.border),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return fallback;
          },
        ),
      ),
    );
  }
}

/// Amber "☀ 2 to review" pill with a breathing glow ring
/// (scale 1.0 → 1.06 → 1.0 over 3s).
class ReviewPill extends StatefulWidget {
  const ReviewPill({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  State<ReviewPill> createState() => _ReviewPillState();
}

class _ReviewPillState extends State<ReviewPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amber = DashPalette.amber;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, child) {
          final b = 0.5 - 0.5 * math.cos(2 * math.pi * _breath.value); // 0→1→0
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Transform.scale(
                  scale: 1 + 0.06 * b,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: amber.withAlpha((90 + 90 * b).round()),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: amber.withAlpha((40 + 60 * b).round()),
                            blurRadius: 10 + 8 * b),
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: amber.withAlpha(34),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_twilight_rounded, size: 16, color: amber),
              const SizedBox(width: 6),
              Text('${widget.count} to review',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: amber)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showProfileSheet(BuildContext context, DashboardStore store,
    String initials, VoidCallback? onSignOut, {String? avatarUrl}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: DashTheme.of(context).card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => AnimatedBuilder(
      animation: store,
      builder: (ctx, _) {
        final p = store.isDark ? DashPalette.dark : DashPalette.light;
        return DashTheme(
          palette: p,
          child: AnimatedContainer(
            duration: Motion.ms(300),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: p.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    DashAvatar(initials: initials, avatarUrl: avatarUrl, size: 56),
                    const SizedBox(height: 20),
                    _SheetRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark mode',
                      trailing: FluidToggle(
                        value: store.isDark,
                        onChanged: (_) => store.toggleTheme(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SheetRow(
                      icon: Icons.logout_rounded,
                      label: 'Sign out',
                      danger: true,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onSignOut?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final color = danger ? const Color(0xFFEF4444) : p.text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.isDark ? p.bg : p.rest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? color : p.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: color)),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

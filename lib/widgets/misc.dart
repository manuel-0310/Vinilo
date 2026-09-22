import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vinilo_theme.dart';
import 'vinyl_disc.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.top = 30,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(VSpace.page, top, VSpace.page, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.display(28, height: 1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: VText.ui(13, color: VColors.text2)),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VColors.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.05),
        );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.labelColor = VColors.accent,
  });

  final String title;
  final String message;
  final Widget? action;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: Column(
        children: [
          VinylDisc(size: 72, labelColor: labelColor)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: VText.display(28, height: 1.05),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: VText.ui(14, color: VColors.text2, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.32),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 20, color: VColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resplandor radial que tiñe la parte alta de una pantalla con el color
/// dominante de una portada.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key, required this.color, this.height = 520});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        height: height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 1.15,
            colors: [
              color.withValues(alpha: 0.62),
              color.withValues(alpha: 0.22),
              VColors.bg.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    this.color = VColors.surface2,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

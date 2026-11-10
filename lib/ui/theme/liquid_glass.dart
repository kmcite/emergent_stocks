import 'package:flutter/material.dart';

/// iOS-style “liquid glass” look using transparency, borders, and gradients only
/// (no [BackdropFilter] / blur).
class LiquidGlassTheme {
  static ThemeData theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5AC8FA),
      brightness: brightness,
      primary: isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF),
    );

    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.65);
    final glassFill = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.58);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SUSE Mono',
      brightness: brightness,
      colorScheme: base,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: base.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.black.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.62),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: base.primary, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: base.primary.withValues(alpha: 0.85),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.5),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _glassFilledStyle(isDark, base, glassBorder),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _glassOutlinedStyle(isDark, base, glassBorder),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _glassTextStyle(isDark, base),
      ),
    );
  }

  static ButtonStyle _glassFilledStyle(
    bool isDark,
    ColorScheme base,
    Color glassBorder,
  ) {
    return FilledButton.styleFrom(
      elevation: 0,
      backgroundColor: base.primary.withValues(alpha: isDark ? 0.55 : 0.72),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.white.withValues(alpha: isDark ? 0.28 : 0.45),
        ),
      ),
    );
  }

  static ButtonStyle _glassOutlinedStyle(
    bool isDark,
    ColorScheme base,
    Color glassBorder,
  ) {
    return OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: base.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      side: BorderSide(color: glassBorder, width: 1.2),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static ButtonStyle _glassTextStyle(bool isDark, ColorScheme base) {
    return TextButton.styleFrom(
      foregroundColor: base.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class GlassCanvas extends StatelessWidget {
  const GlassCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0B1020),
                  const Color(0xFF141A33),
                  const Color(0xFF1A1228),
                ]
              : [
                  const Color(0xFFCFE9FF),
                  const Color(0xFFE8F4FF),
                  const Color(0xFFF2E8FF),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Orb(
              size: 220,
              color: (isDark ? const Color(0xFF64D2FF) : const Color(0xFF007AFF))
                  .withValues(alpha: isDark ? 0.18 : 0.22),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _Orb(
              size: 260,
              color: (isDark ? const Color(0xFFBF5AF2) : const Color(0xFF5E5CE6))
                  .withValues(alpha: isDark ? 0.14 : 0.16),
            ),
          ),
          Positioned(
            top: 180,
            left: 40,
            child: _Orb(
              size: 120,
              color: (isDark ? const Color(0xFF32D74B) : const Color(0xFF34C759))
                  .withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: isDark
                  ? const Color(0xFF080C18).withValues(alpha: 0.72)
                  : const Color(0xFFE8F0FA).withValues(alpha: 0.78),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return GlassCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.58);
    final fill =
        tint ??
        (isDark
            ? Colors.black.withValues(alpha: 0.42)
            : Colors.white.withValues(alpha: 0.72));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fill,
            fill.withValues(alpha: (fill.a * 0.72).clamp(0.04, 1)),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GlassDialogShell extends StatelessWidget {
  const GlassDialogShell({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.onClose,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 10)],
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
// lib/modules/ui/styles.dart
// Theme configuration and styling for JA_PyToCy
// Supports Light/Dark/Auto with transparent blur backgrounds

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../app_config.dart';

/// Theme mode enum
enum AppThemeMode { light, dark, auto }

extension AppThemeModeExt on AppThemeMode {
  String get code {
    switch (this) {
      case AppThemeMode.light: return 'light';
      case AppThemeMode.dark:  return 'dark';
      case AppThemeMode.auto:  return 'auto';
    }
  }

  static AppThemeMode fromCode(String code) {
    switch (code) {
      case 'light': return AppThemeMode.light;
      case 'auto':  return AppThemeMode.auto;
      default:      return AppThemeMode.dark;
    }
  }
}

/// Dynamic theme colors that change based on Light/Dark mode
class AppColors {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgCard;
  final Color bgHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderDefault;
  final Color borderHighlight;
  final Color linkAccent;
  final Color targetAccent;
  final Color statusActive;
  final Color statusRemoved;
  final Color statusChanged;
  final Brightness brightness;

  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgCard,
    required this.bgHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderDefault,
    required this.borderHighlight,
    required this.linkAccent,
    required this.targetAccent,
    required this.statusActive,
    required this.statusRemoved,
    required this.statusChanged,
    required this.brightness,
  });

  // Dark theme colors (transparent for blur)
  static const dark = AppColors(
    bgPrimary: Color(0xDB0B0F19),       // deep dark blue-grey, 86% opacity
    bgSecondary: Color(0xE5111625),     // 90% opacity
    bgTertiary: Color(0xF01A1F2C),      // 94% opacity
    bgCard: Color(0xF5212735),          // 96% opacity
    bgHover: Color(0x1F38BDF8),         // soft sky blue highlight
    textPrimary: Color(0xFFF8FAFC),     // slate 50, crisp white
    textSecondary: Color(0xFFE2E8F0),   // slate 200, highly visible grey
    textMuted: Color(0xFF94A3B8),       // slate 400
    borderDefault: Color(0x2B94A3B8),   // slate 400 with 17% opacity
    borderHighlight: Color(0xFF38BDF8), // sky 400
    linkAccent: Color(0xFF38BDF8),
    targetAccent: Color(0xFF34D399),    // emerald 400
    statusActive: Color(0xFF34D399),
    statusRemoved: Color(0xFFF87171),
    statusChanged: Color(0xFFFBBF24),
    brightness: Brightness.dark,
  );

  // Light theme colors (transparent for blur)
  static const light = AppColors(
    bgPrimary: Color(0xDBF8FAFC),       // slate 50, 86% opacity
    bgSecondary: Color(0xF5FFFFFF),     // 96% opacity
    bgTertiary: Color(0xF2F1F5F9),      // 95% opacity
    bgCard: Color(0xF9FFFFFF),          // 98% opacity
    bgHover: Color(0x190284C7),         // soft sky blue highlight
    textPrimary: Color(0xFF0F172A),     // slate 900
    textSecondary: Color(0xFF334155),   // slate 700, highly visible dark grey
    textMuted: Color(0xFF64748B),       // slate 500
    borderDefault: Color(0x2664748B),   // slate 500 with 15% opacity
    borderHighlight: Color(0xFF0284C7), // sky 600
    linkAccent: Color(0xFF0284C7),
    targetAccent: Color(0xFF0F766E),    // teal 700
    statusActive: Color(0xFF16A34A),
    statusRemoved: Color(0xFFDC2626),
    statusChanged: Color(0xFFD97706),
    brightness: Brightness.light,
  );

  /// Returns a copy of AppColors with fully opaque backgrounds (alpha = 0xFF / opacity = 1.0)
  AppColors getOpaqueCopy() {
    return AppColors(
      bgPrimary: bgPrimary.withOpacity(1.0),
      bgSecondary: bgSecondary.withOpacity(1.0),
      bgTertiary: bgTertiary.withOpacity(1.0),
      bgCard: bgCard.withOpacity(1.0),
      bgHover: bgHover,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      borderDefault: borderDefault,
      borderHighlight: borderHighlight,
      linkAccent: linkAccent,
      targetAccent: targetAccent,
      statusActive: statusActive,
      statusRemoved: statusRemoved,
      statusChanged: statusChanged,
      brightness: brightness,
    );
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'ACTIVE':
        return statusActive;
      case 'FAILED':
      case 'REMOVED':
        return statusRemoved;
      case 'COMPILING':
      case 'CHANGED':
        return statusChanged;
      default:
        return textMuted;
    }
  }
}

/// Extension on BuildContext to easily access custom AppColors
extension AppColorsExtension on BuildContext {
  AppColors get appColors {
    final base = Theme.of(this).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return AppConfig.enableTransparency ? base : base.getOpaqueCopy();
  }
}

/// Theme notifier for global state
class ThemeNotifier extends ChangeNotifier {
  AppThemeMode _mode;
  late AppColors _colors;

  ThemeNotifier(AppThemeMode initialMode, Brightness platformBrightness) : _mode = initialMode {
    _updateColors(platformBrightness);
  }

  AppThemeMode get mode => _mode;
  AppColors get colors => _colors;
  bool get isDark => _colors.brightness == Brightness.dark;

  void _updateColors(Brightness platformBrightness) {
    AppColors baseColors;
    switch (_mode) {
      case AppThemeMode.dark:
        baseColors = AppColors.dark;
        break;
      case AppThemeMode.light:
        baseColors = AppColors.light;
        break;
      case AppThemeMode.auto:
        baseColors = platformBrightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        break;
    }
    _colors = AppConfig.enableTransparency ? baseColors : baseColors.getOpaqueCopy();
  }

  void setMode(AppThemeMode mode, Brightness platformBrightness) {
    if (_mode == mode) return;
    _mode = mode;
    _updateColors(platformBrightness);
    AppConfig.set('theme', mode.code); // persist immediately
    notifyListeners();
  }

  void toggle(Brightness platformBrightness) {
    switch (_mode) {
      case AppThemeMode.dark:
        setMode(AppThemeMode.light, platformBrightness);
        break;
      case AppThemeMode.light:
        setMode(AppThemeMode.auto, platformBrightness);
        break;
      case AppThemeMode.auto:
        setMode(AppThemeMode.dark, platformBrightness);
        break;
    }
  }

  IconData get modeIcon {
    switch (_mode) {
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.auto:
        return Icons.brightness_auto;
    }
  }

  String get modeLabel {
    switch (_mode) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.auto:
        return 'Auto';
    }
  }
}

/// Build ThemeData from AppColors
ThemeData buildThemeData(AppColors c) {
  return ThemeData(
    brightness: c.brightness,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: c.linkAccent,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.linkAccent,
      secondary: c.statusActive,
      surface: c.bgSecondary,
      error: c.statusRemoved,
      onPrimary: c.brightness == Brightness.dark ? const Color(0xFF0D1117) : Colors.white,
      onSecondary: c.brightness == Brightness.dark ? const Color(0xFF0D1117) : Colors.white,
      onSurface: c.textPrimary,
      onError: c.textPrimary,
    ),
    fontFamily: 'Segoe UI',
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgSecondary,
      foregroundColor: c.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: c.borderDefault),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.linkAccent,
        foregroundColor: c.brightness == Brightness.dark ? const Color(0xFF0D1117) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.borderDefault),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.linkAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
      labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.borderDefault),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.bgTertiary,
      contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.bgTertiary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.borderDefault),
      ),
      textStyle: TextStyle(color: c.textPrimary, fontSize: 12),
    ),
    dividerTheme: DividerThemeData(
      color: c.borderDefault,
      thickness: 1,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.linkAccent;
        return Colors.transparent;
      }),
      side: BorderSide(color: c.borderDefault, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

/// Reusable styled widgets
class StyledWidgets {
  /// Status badge with color
  static Widget statusBadge(String status, AppColors c) {
    final color = c.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Section header
  static Widget sectionHeader(String title, AppColors c, {IconData? icon, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.targetAccent),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor ?? c.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Path display with monospace font
  static Widget pathDisplay(String path, {Color? color, AppColors? c}) {
    return Text(
      path,
      style: TextStyle(
        fontFamily: 'Cascadia Code',
        fontSize: 12,
        color: color ?? c?.textSecondary ?? const Color(0xFF8B949E),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Theme Reveal transition
class ThemeReveal extends StatefulWidget {
  final Widget child;
  final ThemeNotifier themeNotifier;

  const ThemeReveal({
    super.key,
    required this.child,
    required this.themeNotifier,
  });

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _oldImage;
  Offset _center = Offset.zero;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _oldImage?.dispose();
          _oldImage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _oldImage?.dispose();
    super.dispose();
  }

  Future<void> triggerReveal({
    required GlobalKey buttonKey,
    required VoidCallback onToggle,
  }) async {
    if (_controller.isAnimating || _oldImage != null) {
      onToggle();
      return;
    }

    try {
      final RenderBox? buttonBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? revealBox = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (buttonBox != null && revealBox != null) {
        final buttonCenterGlobal = buttonBox.localToGlobal(Offset(buttonBox.size.width / 2, buttonBox.size.height / 2));
        _center = revealBox.globalToLocal(buttonCenterGlobal);
      } else {
        _center = Offset.zero;
      }

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio,
        );
        
        setState(() {
          _oldImage = image;
        });

        onToggle();
        _controller.forward(from: 0.0);
      } else {
        onToggle();
      }
    } catch (e) {
      onToggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_oldImage == null) {
      return RepaintBoundary(
        key: _repaintKey,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RawImage(
            image: _oldImage,
            fit: BoxFit.fill,
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ClipPath(
              clipper: CircularRevealClipper(_controller.value, _center),
              child: RepaintBoundary(
                key: _repaintKey,
                child: widget.child,
              ),
            );
          },
        ),
      ],
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  CircularRevealClipper(this.fraction, this.center);

  @override
  Path getClip(Size size) {
    final double maxRadius = _getMaxRadius(size, center);
    final double radius = maxRadius * fraction;

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }

  double _getMaxRadius(Size size, Offset center) {
    final double dx1 = center.dx;
    final double dx2 = size.width - center.dx;
    final double dy1 = center.dy;
    final double dy2 = size.height - center.dy;

    final double maxDx = dx1 > dx2 ? dx1 : dx2;
    final double maxDy = dy1 > dy2 ? dy1 : dy2;

    return math.sqrt(maxDx * maxDx + maxDy * maxDy);
  }
}

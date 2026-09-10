/// Keyboard design system: consistent tokens for backgrounds, keys,
/// text, icons, pressed and active states.
library;

import 'package:flutter/material.dart';

@immutable
class KbTheme extends ThemeExtension<KbTheme> {
  final Color background;
  final Color keyBg;
  final Color keyBgSpecial;
  final Color keyBgPressed;
  final Color keyText;
  final Color keyTextSecondary;
  final Color icon;
  final Color accent;
  final Color accentText;
  final Color stripBg;
  final Color suggestionText;
  final Color border;
  final Color panelBg;

  const KbTheme({
    required this.background,
    required this.keyBg,
    required this.keyBgSpecial,
    required this.keyBgPressed,
    required this.keyText,
    required this.keyTextSecondary,
    required this.icon,
    required this.accent,
    required this.accentText,
    required this.stripBg,
    required this.suggestionText,
    required this.border,
    required this.panelBg,
  });

  factory KbTheme.fromSeed({
    required Color seed,
    required Color accent,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final effectiveAccent = dark
        ? Color.lerp(accent, Colors.white, .18)!
        : Color.lerp(accent, Colors.black, .12)!;
    final luminance = effectiveAccent.computeLuminance();
    final whiteContrast = 1.05 / (luminance + .05);
    final darkContrast = (luminance + .05) / .05;
    final accentText = whiteContrast >= darkContrast
        ? Colors.white
        : const Color(0xFF000000);
    return KbTheme(
      background: dark
          ? Color.alphaBlend(
              seed.withValues(alpha: .12),
              const Color(0xFF17181C),
            )
          : Color.alphaBlend(
              seed.withValues(alpha: .06),
              const Color(0xFFF0F1F4),
            ),
      keyBg: dark ? scheme.surfaceContainerHigh : Colors.white,
      keyBgSpecial: dark
          ? scheme.surfaceContainer
          : Color.alphaBlend(
              seed.withValues(alpha: .10),
              const Color(0xFFE0E3E8),
            ),
      keyBgPressed: dark
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
      keyText: dark ? const Color(0xFFF3F4F7) : const Color(0xFF1A1C20),
      keyTextSecondary: dark
          ? const Color(0xFFBEC2CA)
          : const Color(0xFF565B64),
      icon: dark ? const Color(0xFFD8DAE0) : const Color(0xFF3E434B),
      accent: effectiveAccent,
      accentText: accentText,
      stripBg: dark ? scheme.surfaceContainerLow : const Color(0xFFF8F9FB),
      suggestionText: dark ? const Color(0xFFF3F4F7) : const Color(0xFF1A1C20),
      border: dark ? scheme.outlineVariant : const Color(0xFFD0D4DB),
      panelBg: dark ? scheme.surface : const Color(0xFFFAFBFC),
    );
  }

  static const light = KbTheme(
    background: Color(0xFFE8EAED),
    keyBg: Color(0xFFFFFFFF),
    keyBgSpecial: Color(0xFFCDD1D6),
    keyBgPressed: Color(0xFFB8BCC2),
    keyText: Color(0xFF1F2328),
    keyTextSecondary: Color(0xFF5F6368),
    icon: Color(0xFF444A50),
    accent: Color(0xFF1A73E8),
    accentText: Color(0xFFFFFFFF),
    stripBg: Color(0xFFF1F3F4),
    suggestionText: Color(0xFF1F2328),
    border: Color(0xFFD0D3D8),
    panelBg: Color(0xFFF7F8FA),
  );

  static const dark = KbTheme(
    background: Color(0xFF1B1C1F),
    keyBg: Color(0xFF34363B),
    keyBgSpecial: Color(0xFF26282C),
    keyBgPressed: Color(0xFF4A4D53),
    keyText: Color(0xFFEDEFF2),
    keyTextSecondary: Color(0xFFAEB4BB),
    icon: Color(0xFFC7CCD2),
    accent: Color(0xFF8AB4F8),
    accentText: Color(0xFF17233A),
    stripBg: Color(0xFF232529),
    suggestionText: Color(0xFFEDEFF2),
    border: Color(0xFF3C3F45),
    panelBg: Color(0xFF202226),
  );

  static KbTheme of(BuildContext context) {
    return Theme.of(context).extension<KbTheme>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  KbTheme copyWith({
    Color? background,
    Color? keyBg,
    Color? keyBgSpecial,
    Color? keyBgPressed,
    Color? keyText,
    Color? keyTextSecondary,
    Color? icon,
    Color? accent,
    Color? accentText,
    Color? stripBg,
    Color? suggestionText,
    Color? border,
    Color? panelBg,
  }) {
    return KbTheme(
      background: background ?? this.background,
      keyBg: keyBg ?? this.keyBg,
      keyBgSpecial: keyBgSpecial ?? this.keyBgSpecial,
      keyBgPressed: keyBgPressed ?? this.keyBgPressed,
      keyText: keyText ?? this.keyText,
      keyTextSecondary: keyTextSecondary ?? this.keyTextSecondary,
      icon: icon ?? this.icon,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      stripBg: stripBg ?? this.stripBg,
      suggestionText: suggestionText ?? this.suggestionText,
      border: border ?? this.border,
      panelBg: panelBg ?? this.panelBg,
    );
  }

  @override
  KbTheme lerp(covariant KbTheme? other, double t) {
    if (other == null) return this;
    return KbTheme(
      background: Color.lerp(background, other.background, t)!,
      keyBg: Color.lerp(keyBg, other.keyBg, t)!,
      keyBgSpecial: Color.lerp(keyBgSpecial, other.keyBgSpecial, t)!,
      keyBgPressed: Color.lerp(keyBgPressed, other.keyBgPressed, t)!,
      keyText: Color.lerp(keyText, other.keyText, t)!,
      keyTextSecondary: Color.lerp(
        keyTextSecondary,
        other.keyTextSecondary,
        t,
      )!,
      icon: Color.lerp(icon, other.icon, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      stripBg: Color.lerp(stripBg, other.stripBg, t)!,
      suggestionText: Color.lerp(suggestionText, other.suggestionText, t)!,
      border: Color.lerp(border, other.border, t)!,
      panelBg: Color.lerp(panelBg, other.panelBg, t)!,
    );
  }
}

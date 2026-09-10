import 'package:flutter/material.dart';

import 'kb_theme.dart';

/// A lightweight, asset-free keyboard skin. Every skin is generated from a
/// reviewed seed/accent pair, so previews are fast and no third-party artwork
/// or licensing-sensitive files are bundled in the IME.
class KeyboardSkin {
  const KeyboardSkin({
    required this.id,
    required this.name,
    required this.seed,
    required this.accent,
    this.premium = false,
  });

  final String id;
  final String name;
  final Color seed;
  final Color accent;
  final bool premium;

  KbTheme palette(Brightness brightness) =>
      KbTheme.fromSeed(seed: seed, accent: accent, brightness: brightness);
}

/// Stable IDs are persisted by [KeyboardController]. Never reorder-dependent
/// persistence: a future release may freely rename or regroup display labels.
abstract final class KeyboardSkinCatalog {
  static const defaultId = 'aura';

  static const List<KeyboardSkin> all = [
    KeyboardSkin(
      id: 'aura',
      name: 'Aura',
      seed: Color(0xFF6D5BFF),
      accent: Color(0xFF40D9C2),
    ),
    KeyboardSkin(
      id: 'ocean',
      name: 'Ocean',
      seed: Color(0xFF0066CC),
      accent: Color(0xFF00B8D9),
    ),
    KeyboardSkin(
      id: 'forest',
      name: 'Forest',
      seed: Color(0xFF176B45),
      accent: Color(0xFF4CAF50),
    ),
    KeyboardSkin(
      id: 'sunset',
      name: 'Sunset',
      seed: Color(0xFFE65100),
      accent: Color(0xFFFF8A65),
    ),
    KeyboardSkin(
      id: 'rose',
      name: 'Rose',
      seed: Color(0xFFC2185B),
      accent: Color(0xFFFF80AB),
    ),
    KeyboardSkin(
      id: 'violet',
      name: 'Violet',
      seed: Color(0xFF6A1B9A),
      accent: Color(0xFFB388FF),
    ),
    KeyboardSkin(
      id: 'saffron',
      name: 'Saffron',
      seed: Color(0xFFF57C00),
      accent: Color(0xFFFFB300),
    ),
    KeyboardSkin(
      id: 'indigo',
      name: 'Indigo',
      seed: Color(0xFF283593),
      accent: Color(0xFF536DFE),
    ),
    KeyboardSkin(
      id: 'mint',
      name: 'Mint',
      seed: Color(0xFF00796B),
      accent: Color(0xFF64FFDA),
    ),
    KeyboardSkin(
      id: 'ruby',
      name: 'Ruby',
      seed: Color(0xFF9B111E),
      accent: Color(0xFFFF5252),
    ),
    KeyboardSkin(
      id: 'lotus',
      name: 'Lotus',
      seed: Color(0xFFAD1457),
      accent: Color(0xFFF48FB1),
    ),
    KeyboardSkin(
      id: 'monsoon',
      name: 'Monsoon',
      seed: Color(0xFF37474F),
      accent: Color(0xFF4DD0E1),
    ),
    KeyboardSkin(
      id: 'earth',
      name: 'Earth',
      seed: Color(0xFF5D4037),
      accent: Color(0xFFA1887F),
    ),
    KeyboardSkin(
      id: 'sky',
      name: 'Sky',
      seed: Color(0xFF0277BD),
      accent: Color(0xFF81D4FA),
    ),
    KeyboardSkin(
      id: 'peacock',
      name: 'Peacock',
      seed: Color(0xFF004D40),
      accent: Color(0xFF7E57C2),
    ),
    KeyboardSkin(
      id: 'marigold',
      name: 'Marigold',
      seed: Color(0xFFF9A825),
      accent: Color(0xFFFF6F00),
    ),
    KeyboardSkin(
      id: 'coral',
      name: 'Coral',
      seed: Color(0xFFD84315),
      accent: Color(0xFFFFAB91),
    ),
    KeyboardSkin(
      id: 'jade',
      name: 'Jade',
      seed: Color(0xFF00695C),
      accent: Color(0xFF69F0AE),
    ),
    KeyboardSkin(
      id: 'plum',
      name: 'Plum',
      seed: Color(0xFF6A1B4D),
      accent: Color(0xFFCE93D8),
    ),
    KeyboardSkin(
      id: 'sand',
      name: 'Sand',
      seed: Color(0xFF8D6E63),
      accent: Color(0xFFFFCC80),
    ),
    KeyboardSkin(
      id: 'neon',
      name: 'Neon',
      seed: Color(0xFF263238),
      accent: Color(0xFF00E5FF),
      premium: true,
    ),
    KeyboardSkin(
      id: 'midnight',
      name: 'Midnight',
      seed: Color(0xFF101A43),
      accent: Color(0xFF7C4DFF),
      premium: true,
    ),
    KeyboardSkin(
      id: 'aurora',
      name: 'Aurora',
      seed: Color(0xFF4527A0),
      accent: Color(0xFF00E5A8),
      premium: true,
    ),
    KeyboardSkin(
      id: 'festival',
      name: 'Festival',
      seed: Color(0xFF7B1FA2),
      accent: Color(0xFFFFC107),
      premium: true,
    ),
    KeyboardSkin(
      id: 'terracotta',
      name: 'Terracotta',
      seed: Color(0xFF9C3D2B),
      accent: Color(0xFFE9A178),
      premium: true,
    ),
    KeyboardSkin(
      id: 'himalaya',
      name: 'Himalaya',
      seed: Color(0xFF455A64),
      accent: Color(0xFF90CAF9),
      premium: true,
    ),
    KeyboardSkin(
      id: 'lagoon',
      name: 'Lagoon',
      seed: Color(0xFF006064),
      accent: Color(0xFF18FFFF),
      premium: true,
    ),
    KeyboardSkin(
      id: 'orchid',
      name: 'Orchid',
      seed: Color(0xFF8E24AA),
      accent: Color(0xFFEA80FC),
      premium: true,
    ),
    KeyboardSkin(
      id: 'graphite',
      name: 'Graphite',
      seed: Color(0xFF303030),
      accent: Color(0xFFB0BEC5),
      premium: true,
    ),
    KeyboardSkin(
      id: 'tricolor',
      name: 'Tricolor',
      seed: Color(0xFF1B5E20),
      accent: Color(0xFFFF8F00),
      premium: true,
    ),
  ];

  static KeyboardSkin byId(String? id) =>
      all.firstWhere((skin) => skin.id == id, orElse: () => all.first);

  static bool contains(String? id) => all.any((skin) => skin.id == id);
}

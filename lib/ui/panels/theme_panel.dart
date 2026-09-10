/// Previewable 30-skin keyboard theme catalog with persisted selection.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/keyboard_controller.dart';
import '../kb_theme.dart';
import '../keyboard_skin.dart';
import 'panel_mini_keyboard.dart';

class ThemePanel extends StatelessWidget {
  const ThemePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final kb = context.watch<KeyboardController>();
    final t = KbTheme.of(context);
    final brightness = Theme.of(context).brightness;

    return ColoredBox(
      color: t.panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 8, 2),
            child: Row(
              children: [
                const PanelBackButton(),
                Icon(Icons.palette_outlined, size: 17, color: t.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keyboard skins · ${KeyboardSkinCatalog.all.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.keyText,
                    ),
                  ),
                ),
                _BrightnessButton(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  selected: kb.themeMode == ThemeMode.light,
                  onTap: () => kb.setThemeMode(ThemeMode.light),
                ),
                _BrightnessButton(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  selected: kb.themeMode == ThemeMode.dark,
                  onTap: () => kb.setThemeMode(ThemeMode.dark),
                ),
                _BrightnessButton(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System',
                  selected: kb.themeMode == ThemeMode.system,
                  onTap: () => kb.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 124,
                mainAxisExtent: 72,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
              ),
              itemCount: KeyboardSkinCatalog.all.length,
              itemBuilder: (context, index) {
                final skin = KeyboardSkinCatalog.all[index];
                final selected = kb.keyboardSkinId == skin.id;
                return _SkinCard(
                  skin: skin,
                  palette: skin.palette(brightness),
                  selected: selected,
                  onTap: () => kb.setKeyboardSkin(skin.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrightnessButton extends StatelessWidget {
  const _BrightnessButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = KbTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label appearance',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: selected ? t.accent : t.icon),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final KeyboardSkin skin;
  final KbTheme palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${skin.name} keyboard skin',
      child: Material(
        color: palette.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? palette.accent : palette.border,
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        skin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: palette.keyText,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 14, color: palette.accent)
                    else if (skin.premium)
                      Icon(Icons.auto_awesome, size: 12, color: palette.accent),
                  ],
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Container(
                        height: 23,
                        margin: EdgeInsets.only(right: index == 3 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: index == 3 ? palette.accent : palette.keyBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: palette.border, width: .5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

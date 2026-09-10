import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bhasha_keyboard/core/keyboard_controller.dart';
import 'package:bhasha_keyboard/ui/keyboard_skin.dart';
import 'package:bhasha_keyboard/ui/panels/theme_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog contains 30 stable unique keyboard skins', () {
    expect(KeyboardSkinCatalog.all, hasLength(30));
    expect(
      KeyboardSkinCatalog.all.map((skin) => skin.id).toSet(),
      hasLength(30),
    );
    expect(KeyboardSkinCatalog.byId('missing').id, 'aura');
  });

  test('skin palettes preserve readable key and accent contrast', () {
    for (final skin in KeyboardSkinCatalog.all) {
      for (final brightness in Brightness.values) {
        final palette = skin.palette(brightness);
        expect(
          _contrast(palette.keyText, palette.keyBg),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name} ${brightness.name} key contrast',
        );
        expect(
          _contrast(palette.accentText, palette.accent),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.name} ${brightness.name} accent contrast',
        );
      }
    }
  });

  test('skin selection is persisted by stable ID', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = KeyboardController();
    await Future<void>.delayed(Duration.zero);
    controller.setKeyboardSkin('midnight');
    await Future<void>.delayed(Duration.zero);
    final preferences = await SharedPreferences.getInstance();
    expect(controller.keyboardSkinId, 'midnight');
    expect(preferences.getString('keyboardSkin'), 'midnight');
    controller.dispose();
  });

  testWidgets('theme panel exposes and selects every skin', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = KeyboardController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: Scaffold(body: ThemePanel())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keyboard skins · 30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tricolor'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Tricolor'));
    await tester.pump();
    expect(controller.keyboardSkinId, 'tricolor');
    controller.dispose();
  });
}

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final high = firstLuminance >= secondLuminance
      ? firstLuminance
      : secondLuminance;
  final low = firstLuminance < secondLuminance
      ? firstLuminance
      : secondLuminance;
  return (high + .05) / (low + .05);
}

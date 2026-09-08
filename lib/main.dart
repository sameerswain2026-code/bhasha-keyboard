/// Bhasha Keyboard - premium multilingual keyboard for 22 Indian languages.
/// Web preview hosts the keyboard inside a demo messaging-style editor;
/// on Android the same KeyboardView binds to the IME service.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/keyboard_controller.dart';
import 'engine/appwrite_document_repository.dart';
import 'engine/document_manager.dart';
import 'engine/voice_factory.dart';
import 'ime/android_platform.dart';
import 'ime/ime_bridge.dart';
import 'ui/kb_theme.dart';
import 'ui/keyboard_view.dart';
import 'ui/welcome_flow_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhashaKeyboardApp());
}

/// Entrypoint for the Android IME service (BhashaImeService).
/// Runs only the keyboard surface; text is forwarded to the host app's
/// text field through the InputConnection bridge.
@pragma('vm:entry-point')
void imeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhashaImeApp());
}

class BhashaKeyboardApp extends StatelessWidget {
  const BhashaKeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeyboardController(
        voiceEngine: createVoiceEngine(),
        documentManager: DocumentManager(
          repository: AppwriteDocumentRepository(),
        ),
      ),
      child: Consumer<KeyboardController>(
        builder: (context, kb, _) {
          return MaterialApp(
            title: 'Bhasha Aura',
            debugShowCheckedModeBanner: false,
            themeMode: kb.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: const Color(0xFF6D5BFF),
              scaffoldBackgroundColor: const Color(0xFFF7F8FA),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF40D9C2),
              scaffoldBackgroundColor: const Color(0xFF121316),
            ),
            home: const _AppHome(),
          );
        },
      ),
    );
  }
}

/// Decides whether to show the branded first-run flow before the dashboard.
/// Keyboard setup is deliberately not a launch gate; it is available from
/// Settings and from the welcome flow when the user chooses it.
class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  static const _prefKey = 'welcome_flow_seen';
  bool? _showWelcome;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    if (!isRunningOnAndroidDevice) {
      setState(() => _showWelcome = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _showWelcome = !(prefs.getBool(_prefKey) ?? false));
    } catch (_) {
      setState(() => _showWelcome = false);
    }
  }

  Future<void> _completeWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
    if (mounted) setState(() => _showWelcome = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_showWelcome == true) {
      return WelcomeFlowScreen(onFinished: _completeWelcome);
    }
    return const DemoEditorScreen();
  }
}

/// Root widget for the system IME: keyboard surface only, wired to the
/// host app's text field via ImeBridge (commitText/deleteSurroundingText).
class BhashaImeApp extends StatefulWidget {
  const BhashaImeApp({super.key});

  @override
  State<BhashaImeApp> createState() => _BhashaImeAppState();
}

class _BhashaImeAppState extends State<BhashaImeApp> {
  late final KeyboardController _kb;
  late final ImeBridge _bridge;

  @override
  void initState() {
    super.initState();
    _kb = KeyboardController(
      voiceEngine: createVoiceEngine(),
      documentManager: DocumentManager(
        repository: AppwriteDocumentRepository(),
      ),
    );
    _bridge = ImeBridge(_kb);
    _kb.onEditorActionTriggered = _bridge.performAction;
  }

  @override
  void dispose() {
    _bridge.dispose();
    _kb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<KeyboardController>.value(
      value: _kb,
      child: Consumer<KeyboardController>(
        builder: (context, kb, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: kb.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: const Color(0xFF1A73E8),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: const Color(0xFF8AB4F8),
            ),
            home: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Align(
                alignment: Alignment.bottomCenter,
                child: KeyboardView(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Demo host screen: a messaging-style editor with the keyboard docked
/// at the bottom - mirrors how the IME appears inside Android apps.
class DemoEditorScreen extends StatelessWidget {
  const DemoEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kb = context.watch<KeyboardController>();
    final t = KbTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF40D9C2), Color(0xFF6D5BFF), Color(0xFFE66CFF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x336D5BFF), blurRadius: 14, offset: Offset(0, 5))],
                    ),
                    child: const Center(child: Text('भ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BHASHA AURA', style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w800, color: t.keyText)),
                    Text('Every voice, beautifully understood.', style: TextStyle(fontSize: 10, color: t.keyTextSecondary)),
                  ])),
                  _StatusChip(label: kb.language.englishName, color: t.accent),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Row(children: [
                Expanded(child: _MetricCard(t: t, icon: Icons.language_rounded, value: '22', label: 'languages')),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(t: t, icon: Icons.auto_awesome_rounded, value: 'AURA', label: 'workspace')),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(t: t, icon: Icons.mic_rounded, value: 'LIVE', label: 'voice ready')),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [isDark ? const Color(0xFF1C2034) : Colors.white, isDark ? const Color(0xFF161821) : const Color(0xFFF7F4FF)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border.withValues(alpha: .65)),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 10))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: t.accent),
                    const SizedBox(width: 7),
                    Text('Your private canvas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.keyText)),
                    const Spacer(),
                    if (kb.editor.text.isNotEmpty) TextButton(onPressed: kb.editor.clear, child: const Text('Clear')),
                  ]),
                  const SizedBox(height: 6),
                  Text('Compose in your language. Let Aura do the rest.', style: TextStyle(fontSize: 11, color: t.keyTextSecondary)),
                  const SizedBox(height: 10),
                  Expanded(child: TextField(controller: kb.editor, maxLines: null, expands: true, readOnly: true, showCursor: true, textAlignVertical: TextAlignVertical.top, style: TextStyle(fontSize: 18, height: 1.45, color: t.keyText), decoration: InputDecoration(border: InputBorder.none, hintText: 'नमस्ते! Try typing “namaste”…', hintStyle: TextStyle(fontSize: 16, color: t.keyTextSecondary)))),
                ]),
              ),
            ),
            const KeyboardView(),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .2))), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}

class _MetricCard extends StatelessWidget {
  final KbTheme t;
  final IconData icon;
  final String value;
  final String label;
  const _MetricCard({required this.t, required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9), decoration: BoxDecoration(color: t.keyBg.withValues(alpha: .78), borderRadius: BorderRadius.circular(16), border: Border.all(color: t.border.withValues(alpha: .7))), child: Row(children: [Icon(icon, size: 16, color: t.accent), const SizedBox(width: 6), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.keyText)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, color: t.keyTextSecondary))]))]));
}

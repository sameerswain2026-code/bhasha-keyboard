/// Bhasha Keyboard - premium multilingual keyboard for 22 Indian languages.
/// Web preview hosts the keyboard inside a demo messaging-style editor;
/// on Android the same KeyboardView binds to the IME service.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/models.dart' as models;

import 'config/cloud_config.dart';
import 'core/keyboard_controller.dart';
import 'engine/appwrite_document_repository.dart';
import 'engine/document_manager.dart';
import 'engine/voice_factory.dart';
import 'ime/android_platform.dart';
import 'ime/ime_bridge.dart';
import 'ui/drive_workspace_screen.dart';
import 'ui/kb_theme.dart';
import 'ui/keyboard_skin.dart';
import 'ui/keyboard_view.dart';
import 'ui/panels/documents_panel.dart';
import 'ui/panels/settings_panel.dart';
import 'ui/setup_flow_screen.dart';
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

ThemeData _appTheme(String skinId, Brightness brightness) {
  final skin = KeyboardSkinCatalog.byId(skinId);
  final keyboardTheme = skin.palette(brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: skin.seed,
    scaffoldBackgroundColor: keyboardTheme.panelBg,
    extensions: [keyboardTheme],
  );
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
            theme: _appTheme(kb.keyboardSkinId, Brightness.light),
            darkTheme: _appTheme(kb.keyboardSkinId, Brightness.dark),
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
    // The web/desktop preview is also the widget-test host. Keep it focused
    // on the existing keyboard surface, while Android continues to use the
    // branded companion dashboard after onboarding.
    return isRunningOnAndroidDevice
        ? const CompanionDashboard()
        : const DemoEditorScreen();
  }
}

/// Root widget for the system IME: keyboard surface only, wired to the
/// host app's text field via ImeBridge (commitText/deleteSurroundingText).
/// Companion home shown after onboarding or Google sign-in. This keeps
/// account state and the main feature entry points visible instead of sending
/// the user directly into the demo editor.
class CompanionDashboard extends StatefulWidget {
  const CompanionDashboard({super.key});

  @override
  State<CompanionDashboard> createState() => _CompanionDashboardState();
}

class _CompanionDashboardState extends State<CompanionDashboard> {
  final _cloud = AppwriteDocumentRepository();
  late Future<models.User?> _user;
  bool _accountBusy = false;

  @override
  void initState() {
    super.initState();
    _user = _cloud.currentUser();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _signIn() async {
    if (_accountBusy) return;
    setState(() => _accountBusy = true);
    try {
      await _cloud.signInWithGoogle();
      if (CloudConfig.driveGatewayConfigured) {
        try {
          await _cloud.connectDrive();
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Signed in, but Drive needs to be reconnected from the account menu.',
                ),
              ),
            );
          }
        }
      }
      if (mounted) setState(() => _user = _cloud.currentUser());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google sign-in could not be completed. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _connectDrive() async {
    if (_accountBusy) return;
    setState(() => _accountBusy = true);
    try {
      await _cloud.connectDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive connected.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Drive could not be connected. Sign out, then approve Google access again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _signOut() async {
    if (_accountBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect cloud account?'),
        content: const Text(
          'Bhasha Aura will revoke its saved Drive connection and sign out. '
          'Local keyboard settings remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _accountBusy = true);
    try {
      await _cloud.signOut();
      if (mounted) setState(() => _user = Future.value(null));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_accountBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bhasha cloud account?'),
        content: const Text(
          'This permanently removes your Bhasha cloud account, linked-document metadata, saved Drive token and active sessions. Files in your Google Drive are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _accountBusy = true);
    try {
      await _cloud.deleteAccountAndCloudData();
      if (mounted) setState(() => _user = Future.value(null));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account deletion could not be completed. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accountBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KbTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        title: const Text('Bhasha Aura'),
        actions: [
          IconButton(
            tooltip: 'Refresh account',
            onPressed: () => setState(() => _user = _cloud.currentUser()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<models.User?>(
        future: _user,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final accountLabel = user == null
              ? 'Guest mode · local keyboard ready'
              : (user.name.trim().isEmpty ? user.email : user.name);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Every voice, beautifully understood.',
                style: TextStyle(color: t.keyTextSecondary),
              ),
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: t.accent,
                    child: Icon(Icons.person, color: t.accentText),
                  ),
                  title: Text(accountLabel),
                  subtitle: Text(
                    user == null
                        ? 'Sign in to connect cloud documents'
                        : 'Google account connected',
                  ),
                  trailing: _accountBusy
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : user == null
                      ? FilledButton(
                          onPressed: _signIn,
                          child: const Text('Connect'),
                        )
                      : PopupMenuButton<String>(
                          tooltip: 'Account actions',
                          onSelected: (value) {
                            if (value == 'drive') _connectDrive();
                            if (value == 'signOut') _signOut();
                            if (value == 'delete') _deleteAccount();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'drive',
                              child: Text('Connect or refresh Drive'),
                            ),
                            PopupMenuItem(
                              value: 'signOut',
                              child: Text('Disconnect and sign out'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete cloud account'),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _DashboardAction(
                icon: Icons.keyboard_alt_outlined,
                title: 'Open keyboard workspace',
                subtitle: 'Type, translate, use voice and expressive tools',
                onTap: () => _open(const DemoEditorScreen()),
              ),
              _DashboardAction(
                icon: Icons.folder_outlined,
                title: 'Documents',
                subtitle: 'Link local or authorized cloud document references',
                onTap: () => _open(
                  const Scaffold(body: SafeArea(child: DocumentsPanel())),
                ),
              ),
              _DashboardAction(
                icon: Icons.cloud_outlined,
                title: 'Google Drive workspace',
                subtitle: user == null
                    ? 'Connect your account to browse authorized files'
                    : CloudConfig.driveGatewayConfigured
                    ? 'Browse, search and create authorized Drive items'
                    : 'Cloud gateway is unavailable in this build',
                onTap: user != null && CloudConfig.driveGatewayConfigured
                    ? () => _open(DriveWorkspaceScreen(repository: _cloud))
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            user == null
                                ? 'Connect Google first.'
                                : 'Drive is not configured in this build.',
                          ),
                        ),
                      ),
              ),
              _DashboardAction(
                icon: Icons.settings_outlined,
                title: 'Keyboard settings',
                subtitle: 'Languages, themes, privacy and setup',
                onTap: () => _open(
                  const Scaffold(body: SafeArea(child: SettingsPanel())),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connected features',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AvailabilityChip(
                            label: 'AI tools',
                            available: CloudConfig.aiGatewayConfigured,
                          ),
                          _AvailabilityChip(
                            label: 'Drive',
                            available:
                                user != null &&
                                CloudConfig.driveGatewayConfigured,
                          ),
                          const _AvailabilityChip(
                            label: 'Offline typing',
                            available: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Typed text stays local unless you explicitly use a connected AI, voice, translation or cloud action.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: t.keyTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _open(
                  SetupFlowScreen(
                    onContinue: () => Navigator.of(context).pop(),
                  ),
                ),
                icon: const Icon(Icons.tune),
                label: const Text('Run keyboard setup again'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.label, required this.available});

  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final t = KbTheme.of(context);
    return Semantics(
      label: '$label ${available ? 'available' : 'unavailable'}',
      child: Chip(
        avatar: Icon(
          available ? Icons.check_circle_outline : Icons.do_not_disturb_alt,
          size: 16,
          color: available ? t.accent : t.keyTextSecondary,
        ),
        label: Text(label),
      ),
    );
  }
}

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
            theme: _appTheme(kb.keyboardSkinId, Brightness.light),
            darkTheme: _appTheme(kb.keyboardSkinId, Brightness.dark),
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
                        colors: [
                          Color(0xFF40D9C2),
                          Color(0xFF6D5BFF),
                          Color(0xFFE66CFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x336D5BFF),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'भ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BHASHA AURA',
                          style: TextStyle(
                            fontSize: 13,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: t.keyText,
                          ),
                        ),
                        Text(
                          'Every voice, beautifully understood.',
                          style: TextStyle(
                            fontSize: 10,
                            color: t.keyTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(label: kb.language.englishName, color: t.accent),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      t: t,
                      icon: Icons.language_rounded,
                      value: '22',
                      label: 'languages',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      t: t,
                      icon: Icons.auto_awesome_rounded,
                      value: 'AURA',
                      label: 'workspace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      t: t,
                      icon: Icons.mic_rounded,
                      value: 'LIVE',
                      label: 'voice ready',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF1C2034) : Colors.white,
                      isDark
                          ? const Color(0xFF161821)
                          : const Color(0xFFF7F4FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: t.border.withValues(alpha: .65)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: t.accent,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Your private canvas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.keyText,
                          ),
                        ),
                        const Spacer(),
                        if (kb.editor.text.isNotEmpty)
                          TextButton(
                            onPressed: kb.editor.clear,
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Compose in your language. Let Aura do the rest.',
                      style: TextStyle(fontSize: 11, color: t.keyTextSecondary),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        controller: kb.editor,
                        maxLines: null,
                        expands: true,
                        readOnly: true,
                        showCursor: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.45,
                          color: t.keyText,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'नमस्ते! Try typing “namaste”…',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: t.keyTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final KbTheme t;
  final IconData icon;
  final String value;
  final String label;
  const _MetricCard({
    required this.t,
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
    decoration: BoxDecoration(
      color: t.keyBg.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: t.border.withValues(alpha: .7)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: t.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: t.keyText,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 8.5, color: t.keyTextSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

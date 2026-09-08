import 'package:flutter/material.dart';

import '../engine/appwrite_document_repository.dart';
import 'kb_theme.dart';
import 'setup_flow_screen.dart';

/// First-run branded flow for the companion app. The Android IME entrypoint
/// never uses this screen; keyboard behavior remains unchanged.
class WelcomeFlowScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const WelcomeFlowScreen({super.key, required this.onFinished});

  @override
  State<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends State<WelcomeFlowScreen> {
  final _pageController = PageController();
  final _cloud = AppwriteDocumentRepository();
  int _page = 0;
  bool _loginBusy = false;
  String? _loginError;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onFinished();
    }
  }

  Future<void> _login() async {
    setState(() {
      _loginBusy = true;
      _loginError = null;
    });
    try {
      await _cloud.signInWithGoogle();
      if (mounted) widget.onFinished();
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString();
      setState(() {
        _loginError = raw.contains('project_provider_disabled')
            ? 'Google sign-in is not enabled yet. You can continue without it.'
            : raw.contains('CANCELED') || raw.contains('canceled')
            ? 'Sign-in canceled. You can try again or continue as a guest.'
            : 'Sign-in could not be completed. You can continue as a guest.';
      });
    } finally {
      if (mounted) setState(() => _loginBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KbTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101116) : const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _BrandPage(t: t),
                  _FeaturesPage(t: t),
                  _GetStartedPage(
                    t: t,
                    busy: _loginBusy,
                    error: _loginError,
                    onLogin: _login,
                    onSetup: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SetupFlowScreen(
                            onContinue: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        width: index == _page ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index == _page ? t.accent : t.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_page < 2)
                    TextButton(
                      onPressed: () => _pageController.jumpToPage(2),
                      child: const Text('Skip'),
                    )
                  else
                    TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Continue as guest'),
                    ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _page == 2 ? widget.onFinished : _next,
                    child: Text(_page == 2 ? 'Open dashboard' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPage extends StatelessWidget {
  final KbTheme t;
  const _BrandPage({required this.t});

  @override
  Widget build(BuildContext context) => _PageShell(
    t: t,
    eyebrow: 'WELCOME TO BHASHA',
    title: 'Your voice.\nEvery language.',
    body:
        'A modern keyboard for expressive typing, voice, translation and private document sharing.',
    visual: _BrandVisual(t: t),
  );
}

class _FeaturesPage extends StatelessWidget {
  final KbTheme t;
  const _FeaturesPage({required this.t});

  @override
  Widget build(BuildContext context) => _PageShell(
    t: t,
    eyebrow: 'MADE FOR REAL LIFE',
    title: 'More than\na keyboard.',
    body:
        'Switch languages, speak naturally, translate instantly and keep your important documents organised.',
    visual: Column(
      children: [
        _FeatureTile(
          t: t,
          icon: Icons.language,
          title: '22 languages',
          text: 'Native and Roman typing styles',
        ),
        _FeatureTile(
          t: t,
          icon: Icons.mic_none,
          title: 'Voice-first',
          text: 'Transcribe, translate and auto-insert',
        ),
        _FeatureTile(
          t: t,
          icon: Icons.shield_outlined,
          title: 'Privacy by design',
          text: 'Protected document sharing',
        ),
      ],
    ),
  );
}

class _GetStartedPage extends StatelessWidget {
  final KbTheme t;
  final bool busy;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback onSetup;
  const _GetStartedPage({
    required this.t,
    required this.busy,
    required this.error,
    required this.onLogin,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context) => _PageShell(
    t: t,
    eyebrow: 'YOU ARE IN CONTROL',
    title: 'Start your\nBhasha journey.',
    body:
        'Sign in when you are ready. You can also explore the app first and set up the keyboard later from Settings.',
    visual: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onLogin,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(busy ? 'Connecting…' : 'Continue with Google'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSetup,
            icon: const Icon(Icons.keyboard_alt_outlined),
            label: const Text('Set up keyboard later'),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: TextStyle(fontSize: 11, color: Colors.redAccent)),
        ],
      ],
    ),
  );
}

class _PageShell extends StatelessWidget {
  final KbTheme t;
  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;
  const _PageShell({
    required this.t,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 34, 24, 12),
    children: [
      Text(
        eyebrow,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
          color: t.accent,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        title,
        style: TextStyle(
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: t.keyText,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        body,
        style: TextStyle(fontSize: 14, height: 1.45, color: t.keyTextSecondary),
      ),
      const SizedBox(height: 28),
      visual,
    ],
  );
}

class _BrandVisual extends StatelessWidget {
  final KbTheme t;
  const _BrandVisual({required this.t});

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A73E8), Color(0xFF7C4DFF)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 18, right: 24, child: _Orb(size: 46, opacity: 0.18)),
        Positioned(bottom: 22, left: 26, child: _Orb(size: 64, opacity: 0.12)),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'भ',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

class _FeatureTile extends StatelessWidget {
  final KbTheme t;
  final IconData icon;
  final String title;
  final String text;
  const _FeatureTile({
    required this.t,
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: t.keyBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: t.border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: t.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.keyText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(fontSize: 11, color: t.keyTextSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

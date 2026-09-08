import 'dart:ui';

import 'package:flutter/material.dart';

import '../engine/appwrite_document_repository.dart';
import 'kb_theme.dart';
import 'setup_flow_screen.dart';

/// Premium first-run experience for the Bhasha Aura companion app.
/// The Android IME entrypoint intentionally bypasses this screen.
class WelcomeFlowScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const WelcomeFlowScreen({super.key, required this.onFinished});

  @override
  State<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends State<WelcomeFlowScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _cloud = AppwriteDocumentRepository();
  late final AnimationController _ambient;
  int _page = 0;
  bool _loginBusy = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
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
            ? 'Google sign-in is not enabled yet. You can continue as a guest.'
            : raw.toLowerCase().contains('cancel')
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
      backgroundColor: dark ? const Color(0xFF0A0B10) : const Color(0xFFF8F7FC),
      body: Stack(
        children: [
          _AmbientBackdrop(animation: _ambient, dark: dark),
          SafeArea(
            child: Column(
              children: [
                _TopBrand(t: t, page: _page),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: [
                      _HeroPage(t: t),
                      _FeatureStoryPage(t: t),
                      _LaunchPage(
                        t: t,
                        busy: _loginBusy,
                        error: _loginError,
                        onLogin: _login,
                        onSetup: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 420),
                            pageBuilder: (_, animation, __) => FadeTransition(
                              opacity: animation,
                              child: SetupFlowScreen(
                                onContinue: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomNav(t: t, page: _page, onNext: _next, onSkip: () {
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                  );
                }, onFinish: widget.onFinished),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBrand extends StatelessWidget {
  final KbTheme t;
  final int page;
  const _TopBrand({required this.t, required this.page});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
    child: Row(
      children: [
        const _AuraMark(size: 38),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BHASHA AURA', style: TextStyle(fontSize: 12, letterSpacing: 2.2, fontWeight: FontWeight.w800, color: t.keyText)),
            Text('Every voice, beautifully understood.', style: TextStyle(fontSize: 10, color: t.keyTextSecondary)),
          ],
        ),
        const Spacer(),
        Text('0${page + 1} / 03', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: t.keyTextSecondary)),
      ],
    ),
  );
}

class _HeroPage extends StatelessWidget {
  final KbTheme t;
  const _HeroPage({required this.t});

  @override
  Widget build(BuildContext context) => _StoryPage(
    t: t,
    eyebrow: 'A NEW LANGUAGE OF EXPRESSION',
    title: 'Your voice.\nEvery language.',
    body: 'A beautifully crafted keyboard for the way India speaks, thinks and connects.',
    visual: const _HeroVisual(),
  );
}

class _FeatureStoryPage extends StatelessWidget {
  final KbTheme t;
  const _FeatureStoryPage({required this.t});

  @override
  Widget build(BuildContext context) => _StoryPage(
    t: t,
    eyebrow: 'MORE THAN A KEYBOARD',
    title: 'Small gestures.\nPowerful expression.',
    body: 'Move from thought to message with an intentional toolkit designed around you.',
    visual: Column(
      children: [
        _FeatureCard(t: t, index: '01', icon: Icons.language_rounded, title: '22 Indian languages', text: 'Native scripts, Roman typing and effortless switching.'),
        _FeatureCard(t: t, index: '02', icon: Icons.graphic_eq_rounded, title: 'Voice that keeps up', text: 'Transcribe, translate and let your words flow.'),
        _FeatureCard(t: t, index: '03', icon: Icons.auto_awesome_rounded, title: 'A private toolkit', text: 'Smart tools, documents and expressive media in one place.'),
      ],
    ),
  );
}

class _LaunchPage extends StatelessWidget {
  final KbTheme t;
  final bool busy;
  final String? error;
  final VoidCallback onLogin;
  final VoidCallback onSetup;
  const _LaunchPage({required this.t, required this.busy, required this.error, required this.onLogin, required this.onSetup});

  @override
  Widget build(BuildContext context) => _StoryPage(
    t: t,
    eyebrow: 'MADE FOR YOUR EVERYDAY',
    title: 'Make every\nmessage yours.',
    body: 'Set up your keyboard in a minute, or explore Bhasha Aura first. You stay in control.',
    visual: Column(
      children: [
        SizedBox(width: double.infinity, child: FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: busy ? null : onLogin,
          icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded),
          label: Text(busy ? 'Connecting…' : 'Continue with Google'),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: t.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: onSetup,
          icon: const Icon(Icons.keyboard_alt_rounded),
          label: const Text('Set up keyboard'),
        )),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.redAccent))),
        const SizedBox(height: 16),
        Text('No account required to explore', style: TextStyle(fontSize: 11, color: t.keyTextSecondary)),
      ],
    ),
  );
}

class _StoryPage extends StatelessWidget {
  final KbTheme t;
  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;
  const _StoryPage({required this.t, required this.eyebrow, required this.title, required this.body, required this.visual});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
    children: [
      Text(eyebrow, style: TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: t.accent)),
      const SizedBox(height: 14),
      Text(title, style: TextStyle(fontSize: 38, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.1, color: t.keyText)),
      const SizedBox(height: 14),
      Text(body, style: TextStyle(fontSize: 14, height: 1.5, color: t.keyTextSecondary)),
      const SizedBox(height: 28),
      visual,
    ],
  );
}

class _BottomNav extends StatelessWidget {
  final KbTheme t;
  final int page;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onFinish;
  const _BottomNav({required this.t, required this.page, required this.onNext, required this.onSkip, required this.onFinish});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
    child: Row(
      children: [
        Row(children: List.generate(3, (i) => AnimatedContainer(duration: const Duration(milliseconds: 280), margin: const EdgeInsets.only(right: 6), width: i == page ? 26 : 7, height: 7, decoration: BoxDecoration(color: i == page ? t.accent : t.border, borderRadius: BorderRadius.circular(8)))),
        const Spacer(),
        if (page < 2) TextButton(onPressed: onSkip, child: const Text('Skip')) else TextButton(onPressed: onFinish, child: const Text('Explore as guest')),
        const SizedBox(width: 4),
        FilledButton(onPressed: page == 2 ? onFinish : onNext, child: Text(page == 2 ? 'Open Aura' : 'Continue')),
      ],
    ),
  );
}

class _AuraMark extends StatelessWidget {
  final double size;
  const _AuraMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF40D9C2), Color(0xFF6D5BFF), Color(0xFFE66CFF)]),
      borderRadius: BorderRadius.circular(size * .3),
      boxShadow: [BoxShadow(color: const Color(0xFF6D5BFF).withValues(alpha: .28), blurRadius: size * .35, offset: Offset(0, size * .12))],
    ),
    child: Center(child: Text('भ', style: TextStyle(fontSize: size * .52, fontWeight: FontWeight.w900, color: Colors.white))),
  );
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF171A38), Color(0xFF302269), Color(0xFF133E5B)]),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x334F35C7), blurRadius: 28, offset: Offset(0, 14))],
    ),
    child: Stack(
      children: [
        Positioned(top: 18, right: 22, child: _GlowOrb(size: 72, color: const Color(0xFF40D9C2))),
        Positioned(bottom: 18, left: 20, child: _GlowOrb(size: 56, color: const Color(0xFFE66CFF))),
        Center(child: Container(width: 132, height: 132, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .25))), child: const Center(child: Text('भ', style: TextStyle(fontSize: 76, fontWeight: FontWeight.w900, color: Colors.white))))),
        Positioned(left: 18, bottom: 14, child: _GlassPill(icon: Icons.mic_rounded, label: 'VOICE')),
        Positioned(right: 18, top: 14, child: _GlassPill(icon: Icons.auto_awesome_rounded, label: 'AURA')),
      ],
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color.withValues(alpha: .15), shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: .28), blurRadius: size * .7)]));
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: Colors.white), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Colors.white))])));
}

class _FeatureCard extends StatelessWidget {
  final KbTheme t;
  final String index;
  final IconData icon;
  final String title;
  final String text;
  const _FeatureCard({required this.t, required this.index, required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: t.keyBg.withValues(alpha: .82), borderRadius: BorderRadius.circular(18), border: Border.all(color: t.border.withValues(alpha: .7)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 16, offset: const Offset(0, 8))]), child: Row(children: [Text(index, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.accent)), const SizedBox(width: 12), Container(width: 42, height: 42, decoration: BoxDecoration(gradient: LinearGradient(colors: [t.accent.withValues(alpha: .2), const Color(0xFF7C4DFF).withValues(alpha: .12)]), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: t.accent)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.keyText)), const SizedBox(height: 3), Text(text, style: TextStyle(fontSize: 11, height: 1.3, color: t.keyTextSecondary))]))]));
}

class _AmbientBackdrop extends StatelessWidget {
  final Animation<double> animation;
  final bool dark;
  const _AmbientBackdrop({required this.animation, required this.dark});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: animation, builder: (_, __) => Positioned.fill(child: CustomPaint(painter: _AuraPainter(animation.value, dark))));
}

class _AuraPainter extends CustomPainter {
  final double value;
  final bool dark;
  _AuraPainter(this.value, this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);
    paint.color = const Color(0xFF6D5BFF).withValues(alpha: dark ? .12 : .06);
    canvas.drawCircle(Offset(size.width * (.18 + value * .1), size.height * .22), 130, paint);
    paint.color = const Color(0xFF40D9C2).withValues(alpha: dark ? .08 : .045);
    canvas.drawCircle(Offset(size.width * (.9 - value * .08), size.height * .72), 150, paint);
  }
  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => oldDelegate.value != value || oldDelegate.dark != dark;
}

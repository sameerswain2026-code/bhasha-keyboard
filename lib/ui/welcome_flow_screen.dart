import 'package:flutter/material.dart';

class WelcomeFlowScreen extends StatelessWidget {
  final VoidCallback onFinished;
  const WelcomeFlowScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF40D9C2), Color(0xFF6D5BFF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'भ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Bhasha Keyboard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your comfortable Gboard-style keyboard for 22 Indian languages, voice, translation and expressive typing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.45),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onFinished,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

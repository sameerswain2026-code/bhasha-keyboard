/// Manual translation tool with an in-panel input keyboard.
///
/// The system IME cannot summon a second Android keyboard for its own controls,
/// so the input box opens the compact panel keyboard and remains responsive
/// inside the fixed IME height budget.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/keyboard_controller.dart';
import '../../data/languages.dart';
import '../../engine/transliterator.dart';
import '../kb_theme.dart';
import 'panel_mini_keyboard.dart';

class ManualTranslatePanel extends StatefulWidget {
  const ManualTranslatePanel({super.key});

  @override
  State<ManualTranslatePanel> createState() => _ManualTranslatePanelState();
}

class _ManualTranslatePanelState extends State<ManualTranslatePanel> {
  LanguagePack _source = LanguageRegistry.byId('en');
  LanguagePack _target = LanguageRegistry.byId('hi');
  ScriptMode _outputStyle = ScriptMode.native;
  String? _result;
  bool _busy = false;

  Future<void> _translate(KeyboardController kb) async {
    final input = kb.panelInputText.trim();
    if (input.isEmpty || _busy) return;
    setState(() => _busy = true);
    final output = await kb.translateManualText(
      input,
      _source,
      _target,
      outputStyle: _outputStyle,
    );
    if (!mounted) return;
    setState(() {
      _result = output;
      _busy = false;
    });
  }

  Future<void> _copyResult(KeyboardController kb) async {
    final text = _result;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    kb.addToClipboardHistory(text);
  }

  @override
  Widget build(BuildContext context) {
    final kb = context.watch<KeyboardController>();
    final t = KbTheme.of(context);
    final input = kb.panelInputText;

    return Container(
      color: t.panelBg,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to keyboard',
                icon: Icon(Icons.arrow_back, size: 19, color: t.icon),
                onPressed: kb.closePanel,
              ),
              Icon(Icons.translate, size: 16, color: t.icon),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Manual Translate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.keyText,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear input',
                icon: Icon(Icons.clear, size: 18, color: t.icon),
                onPressed: input.isEmpty && _result == null
                    ? null
                    : () {
                        kb.panelKeyboardClear();
                        setState(() => _result = null);
                      },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _languageDrop(
                  t,
                  'From',
                  _source,
                  (p) => setState(() => _source = p),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward, size: 16, color: t.icon),
              ),
              Expanded(
                child: _languageDrop(
                  t,
                  'To',
                  _target,
                  (p) => setState(() => _target = p),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'Output',
                  style: TextStyle(fontSize: 10, color: t.keyTextSecondary),
                ),
                ChoiceChip(
                  label: const Text('Native', style: TextStyle(fontSize: 11)),
                  selected: _outputStyle == ScriptMode.native,
                  onSelected: (_) =>
                      setState(() => _outputStyle = ScriptMode.native),
                  visualDensity: VisualDensity.compact,
                ),
                ChoiceChip(
                  label: const Text('Roman', style: TextStyle(fontSize: 11)),
                  selected: _outputStyle == ScriptMode.roman,
                  onSelected: (_) =>
                      setState(() => _outputStyle = ScriptMode.roman),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          if (kb.panelKeyboardActive)
            Expanded(child: const PanelMiniKeyboard())
          else ...[
            GestureDetector(
              onTap: () => kb.openPanelKeyboard(initialText: input),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 42, maxHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: t.keyBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: input.isEmpty ? t.border : t.accent,
                  ),
                ),
                child: Text(
                  input.isEmpty ? 'Tap to type text to translate…' : input,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: input.isEmpty ? t.keyTextSecondary : t.keyText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: input.trim().isEmpty || _busy
                    ? null
                    : () => _translate(kb),
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate, size: 16),
                label: Text(_busy ? 'Translating…' : 'Translate'),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: t.keyBg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _result ?? 'Translation appears here',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: t.keyText),
                      ),
                    ),
                    if (_result != null) ...[
                      IconButton(
                        tooltip: 'Copy translation',
                        icon: Icon(Icons.copy, size: 17, color: t.icon),
                        onPressed: () => _copyResult(kb),
                      ),
                      IconButton(
                        tooltip: 'Insert translation',
                        icon: Icon(Icons.input, size: 17, color: t.accent),
                        onPressed: () {
                          kb.insertContent(_result!);
                          kb.closePanel();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _languageDrop(
    KbTheme t,
    String label,
    LanguagePack value,
    ValueChanged<LanguagePack> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: t.keyTextSecondary)),
        SizedBox(
          height: 32,
          child: DropdownButton<String>(
            value: value.id,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            dropdownColor: t.panelBg,
            style: TextStyle(fontSize: 12, color: t.keyText),
            items: [
              for (final p in kLanguagePacks)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(p.englishName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) onChanged(LanguageRegistry.byId(id));
            },
          ),
        ),
      ],
    );
  }
}

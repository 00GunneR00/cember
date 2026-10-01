import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Mirrors the backend's CircleRules limits.
const maxCircleRules = 10;
const maxCircleRuleLength = 140;

/// An editable list of a circle's rules: one field per rule, "Kural ekle" to add, × to remove.
/// Reports the non-empty rules through [onChanged] on every edit.
class RulesEditor extends StatefulWidget {
  const RulesEditor({super.key, this.initialRules = const [], required this.onChanged});

  final List<String> initialRules;
  final ValueChanged<List<String>> onChanged;

  @override
  State<RulesEditor> createState() => _RulesEditorState();
}

class _RulesEditorState extends State<RulesEditor> {
  late final List<TextEditingController> _fields = [for (final rule in widget.initialRules) TextEditingController(text: rule)];

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged([for (final f in _fields) f.text.trim()].where((r) => r.isNotEmpty).toList());

  void _add() {
    if (_fields.length >= maxCircleRules) return;
    setState(() => _fields.add(TextEditingController()));
  }

  void _remove(int index) {
    final removed = _fields.removeAt(index);
    setState(() {});
    removed.dispose();
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, field) in _fields.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('${i + 1}.', style: AppTextStyles.labelMd.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: field,
                    autofocus: field.text.isEmpty && i == _fields.length - 1,
                    maxLength: maxCircleRuleLength,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Ör. Herkes en az 3 kare atar', counterText: '', isDense: true),
                    onChanged: (_) => _report(),
                  ),
                ),
                IconButton(
                  onPressed: () => _remove(i),
                  tooltip: 'Kuralı sil',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        if (_fields.length < maxCircleRules)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add,
              icon: Icon(Icons.add, size: 18, color: colors.secondary),
              label: Text(_fields.isEmpty ? 'Kural ekle' : 'Bir kural daha', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
            ),
          ),
      ],
    );
  }
}

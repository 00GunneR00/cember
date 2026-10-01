import 'package:flutter/material.dart';

import '../../models/circle_photo.dart';
import '../../models/report_reason.dart';
import '../../theme/app_theme.dart';

/// Each action returns a user-facing error, or null on success.
typedef PhotoAction = Future<String?> Function();
typedef ReportAction = Future<String?> Function(ReportReason reason, String? note);

/// The "⋯" menu on a photo: delete for its uploader and the circle owner; report or block for everyone else.
Future<void> showPhotoActions(
  BuildContext context, {
  required CirclePhoto photo,
  required PhotoAction onDelete,
  required ReportAction onReport,
  required PhotoAction onBlock,
}) async {
  final colors = context.colors;
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: colors.surface,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo.viewerCanDelete)
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text('Fotoğrafı Sil', style: TextStyle(color: colors.error)),
              onTap: () => Navigator.of(context).pop('delete'),
            )
          else ...[
            ListTile(
              leading: Icon(Icons.flag_outlined, color: colors.onSurface),
              title: const Text('Şikayet Et'),
              subtitle: const Text('Bu fotoğrafı artık görmezsin'),
              onTap: () => Navigator.of(context).pop('report'),
            ),
            ListTile(
              leading: Icon(Icons.block, color: colors.onSurface),
              title: Text('${photo.uploader} kişisini engelle'),
              subtitle: const Text('Paylaştığı fotoğrafları ve yorumları görmezsin'),
              onTap: () => Navigator.of(context).pop('block'),
            ),
          ],
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case 'delete':
      final confirmed = await _confirm(
        context,
        title: 'Fotoğraf silinsin mi?',
        message: 'Fotoğraf çemberden kalıcı olarak silinir. Bu geri alınamaz.',
        action: 'Sil',
      );
      if (!confirmed) return;
      final failure = await onDelete();
      if (context.mounted) _report(context, failure, success: 'Fotoğraf silindi.');
    case 'report':
      final result = await showModalBottomSheet<(ReportReason, String?)>(
        context: context,
        isScrollControlled: true,
        backgroundColor: colors.surface,
        builder: (_) => const _ReportSheet(),
      );
      if (result == null) return;
      final failure = await onReport(result.$1, result.$2);
      if (context.mounted) _report(context, failure, success: 'Teşekkürler, şikayetin alındı. Ekibimiz inceleyecek.');
    case 'block':
      final confirmed = await _confirm(
        context,
        title: '${photo.uploader} engellensin mi?',
        message: 'Bu kişinin paylaştığı fotoğrafları ve yorumları artık görmezsin. Engeli Profil > Engellenen Kişiler\'den kaldırabilirsin.',
        action: 'Engelle',
      );
      if (!confirmed) return;
      final failure = await onBlock();
      if (context.mounted) _report(context, failure, success: '${photo.uploader} engellendi.');
  }
}

Future<bool> _confirm(BuildContext context, {required String title, required String message, required String action}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Vazgeç')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
      ],
    ),
  );
  return confirmed == true;
}

void _report(BuildContext context, String? failure, {required String success}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure ?? success)));
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Neden şikayet ediyorsun?', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
              const SizedBox(height: AppSpacing.xs),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.secondary,
                        title: Text(reason.label, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Eklemek istediğin bir not var mı? (opsiyonel)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _reason == null
                    ? null
                    : () {
                        final note = _note.text.trim();
                        Navigator.of(context).pop((_reason!, note.isEmpty ? null : note));
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
                child: const Text('Şikayeti Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../core/api_client.dart';
import '../core/circle_sharing.dart';
import '../core/reveal_time.dart';
import '../data/http/http_qr_invite_repository.dart';
import '../models/challenge_template.dart';
import '../models/photo_upload_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common/gradient_button.dart';
import 'circle_detail_screen.dart';

/// A challenge's full card: how to play, its photo tasks, its settings — and "Challenge'ı Başlat",
/// which creates the user's own circle from it and shares the invite right away.
class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challenge, required this.apiClient});

  final ChallengeTemplate challenge;
  final ApiClient? apiClient;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _starting = false;

  ChallengeTemplate get _challenge => widget.challenge;

  String get _uploadModeLabel => switch (_challenge.uploadMode) {
    PhotoUploadMode.quickCaptureOnly => 'Sadece Şipşak — fotoğraflar o an çekilir',
    PhotoUploadMode.galleryOnly => 'Sadece galeriden',
    PhotoUploadMode.both => 'Şipşak ve galeriden',
  };

  String get _revealLabel {
    final days = _challenge.revealAfterDays;
    if (days == null) return 'Banyo yok, fotoğraflar anında görünür';
    final hour = '${_challenge.revealHour.toString().padLeft(2, '0')}:00';
    return switch (days) {
      0 => 'Banyo: fotoğraflar aynı gün $hour\'de açılır',
      1 => 'Banyo: fotoğraflar ertesi gün $hour\'de açılır',
      _ => 'Banyo: fotoğraflar $days gün sonra $hour\'de açılır',
    };
  }

  Future<void> _start() async {
    final setup = await showModalBottomSheet<_StartSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => _StartSheet(challenge: _challenge),
    );
    if (setup == null || !mounted) return;
    if (!Get.isRegistered<AlbumsController>(tag: 'albums')) return;

    setState(() => _starting = true);
    final created = await Get.find<AlbumsController>(tag: 'albums').createCircle(
      setup.name,
      eventDate: setup.eventDay,
      isOpenJoin: false,
      description: _challenge.tagline,
      uploadMode: _challenge.uploadMode,
      revealAt: setup.revealAt,
      challengeTemplateId: _challenge.id,
    );
    if (!mounted) return;
    setState(() => _starting = false);
    final circleId = created.id;
    if (circleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(created.error ?? 'Çember oluşturulamadı, tekrar dene.')));
      return;
    }

    // The point of a challenge is bringing friends in — offer the invite straight away.
    final client = widget.apiClient;
    if (client != null) {
      try {
        final invite = await HttpQrInviteRepository(client).fetch(circleId);
        await shareInviteLink(
          eventName: setup.name,
          inviteUrl: invite.inviteUrl,
          message: '${_challenge.emoji} "${setup.name}" çemberinde ${_challenge.title} challenge\'ı başladı! Katıl, birlikte çekelim:',
        );
      } catch (_) {
        // Sharing can be done later from the circle's "Davet Et".
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CircleDetailScreen(circleId: circleId, apiClient: widget.apiClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: _challenge.gradientStart,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_challenge.gradientStart, _challenge.gradientEnd]),
                ),
                child: Center(child: Text(_challenge.emoji, style: const TextStyle(fontSize: 72))),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 120),
            sliver: SliverList.list(
              children: [
                Text(_challenge.title, style: AppTextStyles.headlineLgMobile.copyWith(color: colors.primary)),
                const SizedBox(height: 4),
                Text(_challenge.tagline, style: AppTextStyles.bodyLg.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(_challenge.creatorLabel, style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                    if (_challenge.creatorVerified) ...[const SizedBox(width: 3), Icon(Icons.verified, size: 14, color: colors.secondary)],
                    if (_challenge.startedCount > 0)
                      Text(' · ${_challenge.startedCount} grup başlattı', style: AppTextStyles.labelMd.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Nasıl oynanır', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                const SizedBox(height: 6),
                Text(_challenge.description, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSpacing.lg),
                Text('Kurallar', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                const SizedBox(height: 6),
                for (final (i, prompt) in _challenge.prompts.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: colors.secondaryContainer, shape: BoxShape.circle),
                          child: Text(
                            '${i + 1}',
                            style: AppTextStyles.labelSm.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(prompt, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('Ayarlar', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
                const SizedBox(height: 6),
                _SettingRow(icon: Icons.photo_camera_outlined, text: _uploadModeLabel),
                _SettingRow(icon: Icons.photo_filter, text: _revealLabel),
                const _SettingRow(icon: Icons.lock_outline, text: 'Kilitli: sadece davet ettiğin kişiler katılır'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, 0, AppSpacing.marginMobile, AppSpacing.md),
        child: SizedBox(
          height: 52,
          child: GradientButton(
            onPressed: _starting ? null : _start,
            borderRadius: AppRadius.pill,
            child: _starting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSecondary))
                : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow_rounded), SizedBox(width: 6), Text('Challenge\'ı Başlat')]),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _StartSetup {
  const _StartSetup(this.name, this.eventDay, this.revealAt);

  final String name;
  final DateTime eventDay;
  final DateTime? revealAt;
}

/// Name, day and (for Banyo challenges) the reveal moment — pre-filled from the challenge, all editable.
class _StartSheet extends StatefulWidget {
  const _StartSheet({required this.challenge});

  final ChallengeTemplate challenge;

  @override
  State<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends State<_StartSheet> {
  late final _name = TextEditingController(text: widget.challenge.title);
  DateTime _eventDay = DateUtils.dateOnly(DateTime.now());
  late DateTime? _revealAt = _suggestedReveal();
  bool _revealEdited = false;

  /// The challenge's suggestion for the chosen day; if that moment has already passed, the same hour tomorrow.
  DateTime? _suggestedReveal() {
    final suggested = widget.challenge.suggestedRevealAt(_eventDay);
    if (suggested == null) return null;
    if (suggested.isAfter(DateTime.now())) return suggested;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, widget.challenge.revealHour);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDay,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _eventDay = picked;
      if (!_revealEdited) _revealAt = _suggestedReveal();
    });
  }

  Future<void> _pickReveal() async {
    final picked = await pickRevealTime(context, _revealAt ?? defaultRevealTime(_eventDay));
    if (picked == null) return;
    setState(() {
      _revealAt = picked;
      _revealEdited = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final day = '${_eventDay.day.toString().padLeft(2, '0')}.${_eventDay.month.toString().padLeft(2, '0')}.${_eventDay.year}';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${widget.challenge.emoji} Çemberini hazırla', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _name,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Çemberin adı', counterText: ''),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: colors.secondary),
                title: const Text('Etkinlik günü'),
                subtitle: Text(day),
                trailing: Text('Değiştir', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                onTap: _pickDay,
              ),
              if (_revealAt != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_filter, color: colors.secondary),
                  title: const Text('Fotoğraflar açılıyor'),
                  subtitle: Text(formatRevealTime(_revealAt!)),
                  trailing: Text('Değiştir', style: AppTextStyles.labelMd.copyWith(color: colors.secondary)),
                  onTap: _pickReveal,
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 50,
                child: GradientButton(
                  borderRadius: AppRadius.pill,
                  onPressed: () {
                    final name = _name.text.trim();
                    if (name.isEmpty) return;
                    // A reveal chosen a while ago may have slipped into the past while the sheet was open.
                    final reveal = _revealAt != null && _revealAt!.isAfter(DateTime.now()) ? _revealAt : _suggestedReveal();
                    Navigator.of(context).pop(_StartSetup(name, _eventDay, reveal));
                  },
                  child: const Text('Oluştur ve Arkadaşlarını Davet Et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

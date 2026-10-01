import 'package:flutter/material.dart';

import '../data/blocked_users_source.dart';
import '../theme/app_theme.dart';

/// Profil > Engellenen Kişiler: people whose photos and comments the user chose to hide.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key, required this.source});

  final BlockedUsersSource source;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late Future<List<BlockedEntry>> _entries = widget.source.load();

  Future<void> _unblock(BlockedEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await entry.unblock();
      // Block body, not an arrow: a setState callback must not return the Future.
      setState(() {
        _entries = widget.source.load();
      });
      messenger.showSnackBar(SnackBar(content: Text('${entry.user.displayName} artık engelli değil.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Engel kaldırılamadı, tekrar dene.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Engellenen Kişiler', style: AppTextStyles.headlineSm.copyWith(color: colors.primary)),
      ),
      body: FutureBuilder<List<BlockedEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Liste yüklenemedi.', style: AppTextStyles.bodyMd.copyWith(color: colors.onSurface)),
            );
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Kimseyi engellemedin. Bir fotoğrafın ⋯ menüsünden birini engelleyebilirsin.',
                  style: AppTextStyles.bodyMd.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              for (final entry in entries)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.surfaceContainerHigh,
                    child: Icon(Icons.person, color: colors.onSurfaceVariant),
                  ),
                  title: Text(entry.user.displayName, style: AppTextStyles.labelLg.copyWith(color: colors.primary)),
                  subtitle: Text(
                    entry.user.circleName == null ? 'Tüm çemberlerde' : 'Sadece "${entry.user.circleName}" çemberinde',
                    style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                  ),
                  trailing: TextButton(onPressed: () => _unblock(entry), child: const Text('Engeli Kaldır')),
                ),
            ],
          );
        },
      ),
    );
  }
}

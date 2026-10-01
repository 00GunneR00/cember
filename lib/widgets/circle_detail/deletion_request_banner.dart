import 'package:flutter/material.dart';

import '../../models/deletion_request_status.dart';
import '../../theme/app_theme.dart';

class DeletionRequestBanner extends StatelessWidget {
  const DeletionRequestBanner({
    super.key,
    required this.status,
    required this.viewerIsHost,
    required this.onCancel,
    required this.onApprove,
    required this.onDecline,
  });

  final DeletionRequestStatus status;
  final bool viewerIsHost;
  final VoidCallback onCancel;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progressLabel = '${status.currentApprovals}/${status.requiredApprovals} onay';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: colors.onErrorContainer),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${status.requestedByDisplayName ?? 'Ev sahibi'} bu çemberi silmek istiyor · $progressLabel',
                  style: AppTextStyles.bodySm.copyWith(color: colors.onErrorContainer, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;
    if (viewerIsHost) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: onCancel, child: const Text('İptal Et')),
      );
    }
    if (!status.viewerIsEligible) {
      return Text('Bu talebi sadece etkileşimde bulunan katılımcılar onaylayabilir.', style: AppTextStyles.labelSm.copyWith(color: colors.onErrorContainer));
    }
    if (status.viewerVote != null) {
      return Text(
        status.viewerVote! ? 'Oyunu kullandın: Onayladın.' : 'Oyunu kullandın: Reddettin.',
        style: AppTextStyles.labelSm.copyWith(color: colors.onErrorContainer, fontWeight: FontWeight.w600),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: onDecline, child: const Text('Reddet')),
        const SizedBox(width: AppSpacing.xs),
        FilledButton(onPressed: onApprove, child: const Text('Onayla')),
      ],
    );
  }
}

class DeletionRequestStatus {
  const DeletionRequestStatus({
    required this.isPending,
    required this.requestedByDisplayName,
    required this.eligibleVoterCount,
    required this.requiredApprovals,
    required this.currentApprovals,
    required this.viewerIsEligible,
    required this.viewerVote,
    required this.deleted,
  });

  final bool isPending;
  final String? requestedByDisplayName;
  final int eligibleVoterCount;
  final int requiredApprovals;
  final int currentApprovals;
  final bool viewerIsEligible;
  final bool? viewerVote;
  final bool deleted;

  factory DeletionRequestStatus.fromJson(Map<String, dynamic> json) => DeletionRequestStatus(
        isPending: json['isPending'] as bool,
        requestedByDisplayName: json['requestedByDisplayName'] as String?,
        eligibleVoterCount: json['eligibleVoterCount'] as int,
        requiredApprovals: json['requiredApprovals'] as int,
        currentApprovals: json['currentApprovals'] as int,
        viewerIsEligible: json['viewerIsEligible'] as bool,
        viewerVote: json['viewerVote'] as bool?,
        deleted: json['deleted'] as bool,
      );
}

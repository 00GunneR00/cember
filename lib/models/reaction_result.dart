class ReactionResult {
  const ReactionResult({required this.reacted, required this.reactionCount});

  final bool reacted;
  final int reactionCount;

  factory ReactionResult.fromJson(Map<String, dynamic> json) => ReactionResult(
        reacted: json['reacted'] as bool,
        reactionCount: json['reactionCount'] as int,
      );
}

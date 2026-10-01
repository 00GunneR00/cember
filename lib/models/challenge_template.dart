import 'package:flutter/material.dart';

import 'photo_upload_mode.dart';

enum ChallengeCategory {
  gece('Gece', 'Gece & Parti'),
  kutlama('Kutlama', 'Kutlama'),
  gezi('Gezi', 'Gezi'),
  gunluk('Gunluk', 'Günlük'),
  spor('Spor', 'Spor'),
  dugun('Dugun', 'Düğün & Kına');

  const ChallengeCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ChallengeCategory fromApi(String value) => values.firstWhere((c) => c.apiValue == value, orElse: () => ChallengeCategory.gunluk);
}

Color _hex(String value) {
  var hex = value.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

/// A ready-made circle idea from Keşfet > Challenge. Starting it creates the user's own circle with
/// these settings, and its prompts show inside that circle.
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.id,
    required this.slug,
    required this.title,
    required this.tagline,
    required this.description,
    required this.emoji,
    required this.category,
    required this.gradientStart,
    required this.gradientEnd,
    required this.uploadMode,
    required this.revealAfterDays,
    required this.revealHour,
    required this.prompts,
    required this.startedCount,
    this.creatorName,
    this.creatorHandle,
    this.creatorVerified = false,
    this.isFeatured = false,
  });

  final String id;
  final String slug;
  final String title;
  final String tagline;
  final String description;
  final String emoji;
  final ChallengeCategory category;
  final Color gradientStart;
  final Color gradientEnd;
  final PhotoUploadMode uploadMode;

  /// Banyo default: reveal this many days after the event day, at [revealHour]. Null = no Banyo.
  final int? revealAfterDays;
  final int revealHour;
  final List<String> prompts;
  final int startedCount;
  final String? creatorName;
  final String? creatorHandle;
  final bool creatorVerified;
  final bool isFeatured;

  bool get usesBanyo => revealAfterDays != null;

  /// Who the card credits: the influencer when there is one, otherwise Çember.
  String get creatorLabel => creatorHandle ?? creatorName ?? 'Çember';

  /// The suggested reveal moment for a circle held on [eventDay], or null without Banyo.
  DateTime? suggestedRevealAt(DateTime eventDay) {
    final days = revealAfterDays;
    if (days == null) return null;
    return DateTime(eventDay.year, eventDay.month, eventDay.day + days, revealHour);
  }

  factory ChallengeTemplate.fromJson(Map<String, dynamic> json) => ChallengeTemplate(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    tagline: json['tagline'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    category: ChallengeCategory.fromApi(json['category'] as String),
    gradientStart: _hex(json['gradientStartHex'] as String),
    gradientEnd: _hex(json['gradientEndHex'] as String),
    uploadMode: PhotoUploadMode.fromApi(json['uploadMode'] as String? ?? 'Both'),
    revealAfterDays: json['revealAfterDays'] as int?,
    revealHour: json['revealHour'] as int? ?? 10,
    prompts: (json['prompts'] as List).cast<String>(),
    startedCount: json['startedCount'] as int? ?? 0,
    creatorName: json['creatorName'] as String?,
    creatorHandle: json['creatorHandle'] as String?,
    creatorVerified: json['creatorVerified'] as bool? ?? false,
    isFeatured: json['isFeatured'] as bool? ?? false,
  );
}

/// The challenge a circle was started from — its prompts are the circle's photo tasks.
class CircleChallenge {
  const CircleChallenge({required this.id, required this.title, required this.emoji, required this.prompts, this.creatorHandle});

  final String id;
  final String title;
  final String emoji;
  final List<String> prompts;
  final String? creatorHandle;

  factory CircleChallenge.fromJson(Map<String, dynamic> json) => CircleChallenge(
    id: json['id'] as String,
    title: json['title'] as String,
    emoji: json['emoji'] as String,
    prompts: (json['prompts'] as List).cast<String>(),
    creatorHandle: (json['creatorHandle'] ?? json['creatorName']) as String?,
  );
}

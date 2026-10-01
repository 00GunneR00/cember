import 'package:flutter/material.dart';

class ProfileCollection {
  const ProfileCollection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.previewUrls,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final List<String> previewUrls;
}

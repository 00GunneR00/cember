import 'package:flutter/material.dart';

class SettingsItem {
  const SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
    this.hasToggle = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final bool hasToggle;

  SettingsItem copyWith({String? subtitle}) {
    return SettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      destructive: destructive,
      hasToggle: hasToggle,
    );
  }
}

import 'package:flutter/material.dart';

class BrandProfile {
  const BrandProfile({
    required this.id,
    required this.name,
    required this.primaryColor,
    this.logoUrl,
    this.secondaryColor,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final Color primaryColor;
  final Color? secondaryColor;

  static Color _parseHex(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }

  factory BrandProfile.fromJson(Map<String, dynamic> json) => BrandProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        logoUrl: json['logoUrl'] as String?,
        primaryColor: _parseHex(json['primaryColorHex'] as String),
        secondaryColor: json['secondaryColorHex'] == null
            ? null
            : _parseHex(json['secondaryColorHex'] as String),
      );
}

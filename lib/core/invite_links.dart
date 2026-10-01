import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Pulls the invite token out of anything that carries one:
/// `https://cember.app/join/{token}`, `cember://join/{token}`, or a bare token (older QR codes).
String? extractInviteToken(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return trimmed;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  // cember://join/{token} parses "join" as the host, leaving the token as the only path segment.
  if (uri.scheme == 'cember') {
    return uri.host == 'join' && segments.length == 1 ? segments.first : null;
  }
  if (segments.isEmpty) return null;
  final joinIndex = segments.indexOf('join');
  // Invite URLs are "{InviteBaseUrl}/{token}"; the base URL is configurable, so fall back to the last segment.
  return joinIndex >= 0 && joinIndex + 1 < segments.length ? segments[joinIndex + 1] : segments.last;
}

/// Invite links opened from outside the app (WhatsApp, SMS, …). The token waits in [pendingToken]
/// until a signed-in screen takes it — so a link that launched the app before sign-in isn't lost.
class InviteLinks {
  InviteLinks._();

  static final instance = InviteLinks._();

  final pendingToken = ValueNotifier<String?>(null);
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    final appLinks = AppLinks();
    // uriLinkStream also delivers the link that cold-started the app.
    _subscription = appLinks.uriLinkStream.listen(_handle, onError: (_) {});
  }

  void _handle(Uri uri) {
    final token = extractInviteToken(uri.toString());
    if (token != null) pendingToken.value = token;
  }

  /// Hands the pending token to the caller exactly once.
  String? take() {
    final token = pendingToken.value;
    pendingToken.value = null;
    return token;
  }
}

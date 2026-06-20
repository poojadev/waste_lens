import 'package:flutter/widgets.dart';

/// Self-contained palette + text styles for the overlay.
///
/// The overlay sits above the host app and must not borrow its theme, so it
/// carries its own "evidence ledger" tokens. Monospace is the ledger's voice.
abstract final class OverlayTokens {
  static const Color ink = Color(0xFF16140F); // warmed graphite base
  static const Color paper = Color(0xFFE8E1D0); // aged-paper foreground
  static const Color charge = Color(0xFFE0A52E); // evidence amber = waste
  static const Color verdict = Color(0xFFC8442E); // red = leaks / severe
  static const Color cleared = Color(0xFF5FA67A); // sage = healthy
  static const Color mark = Color(0xFF7C5CFF); // wordmark only

  static const Color panel = Color(0xF21C1A14); // ~95% opaque ink
  static const Color hairline = Color(0x33E8E1D0);

  static const String _mono = 'monospace';

  static const TextStyle label = TextStyle(
    color: paper,
    fontSize: 11,
    height: 1.2,
    fontFamily: _mono,
    decoration: TextDecoration.none,
  );

  static const TextStyle value = TextStyle(
    color: paper,
    fontSize: 15,
    height: 1.1,
    fontFamily: _mono,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  static const TextStyle eyebrow = TextStyle(
    color: charge,
    fontSize: 9,
    height: 1.2,
    letterSpacing: 1.5,
    fontFamily: _mono,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );
}

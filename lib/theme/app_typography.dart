import 'package:flutter/material.dart';
import 'package:circle_war/constant.dart';

/// Unified typography system for circle-war.
///
/// Hierarchy:
///   display  (64) → Hero title only ("AREA")
///   headline (32) → Secondary hero ("FILL YOUR"), medium scores
///   title    (24) → Screen / dialog titles
///   subtitle (20) → Section headers, appbar titles
///   body     (16) → Primary body text, descriptions
///   bodySmall(14) → Secondary text, emails, hints
///   label    (12) → Uppercase labels ("BEST SCORE", "MY BEST")
///   caption  (11) → Small informational text
///   tiny      (9) → Micro badges ("ME")
///
/// Scores:
///   scoreDisplay (48) → Large score numbers
///   scoreMedium  (32) → Score bar numbers
///
/// Buttons:
///   button      (16) → Standard button text
///   buttonLarge (24) → Primary button (use with BlackHanSans)
///   buttonSmall (18) → Secondary button (use with BlackHanSans)
///
/// Weights (only 4 in use):
///   w900 → Titles and scores (maximum impact)
///   w800 → Labels and buttons (emphasis)
///   w600 → Body text (readability)
///   w500 → Secondary/subdued body text
///
/// Letter spacing rules:
///   Negative → Large display text (tighter at big sizes)
///   Zero     → Body and score text
///   Positive → Uppercase labels (aids ALL-CAPS readability)
class AppTypography {
  AppTypography._(); // prevent instantiation

  // ─── Display ───────────────────────────────────────────
  static const display = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: -2.0,
    height: 1.0,
    color: charcoalBlack,
  );

  static const headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.2,
    color: charcoalBlack,
  );

  // ─── Titles ────────────────────────────────────────────
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.2,
    color: charcoalBlack,
  );

  static const subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    color: charcoalBlack,
  );

  // ─── Body ──────────────────────────────────────────────
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: charcoalBlack,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: charcoalBlack,
  );

  // ─── Labels (UPPERCASE) ────────────────────────────────
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: charcoalBlack,
  );

  // ─── Buttons ───────────────────────────────────────────
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    color: charcoalBlack,
  );

  // ─── Scores ────────────────────────────────────────────
  static const scoreDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: charcoalBlack,
  );

  static const scoreMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: charcoalBlack,
  );

  // ─── Small ─────────────────────────────────────────────
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: charcoalBlack,
  );

  static const tiny = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    color: charcoalBlack,
  );
}

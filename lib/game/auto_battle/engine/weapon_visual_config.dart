import 'package:flutter/material.dart';
import '../auto_battle_palette.dart';

/// ⚔️ Weapon Visual Tuning Configuration
/// You can adjust the look, feel, and size of weapons here.
class WeaponVisualConfig {
  // ── Global Sketch Settings ──
  static const double globalJitter = 0.8;       // How much the lines "shake" (0.0 for clean lines)
  static const double inkStrokeWidth = 3.2;     // Thickness of the black ink outlines
  static const double hatchingSpacing = 3.5;    // Spacing between sketchy shadow lines
  static const Color inkColor = AutoBattlePalette.ink;

  // 🔫 GUNNER (Revolver)
  static const double gunFrameScaleX = 1.9;     // Length of the main frame
  static const double gunFrameScaleY = 8.0;     // Height of the main frame
  static const double gunBarrelScale = 2.4;     // How far the barrel sticks out
  static const double gunGripLength = 22.0;     // Length of the handle
  static const double gunRecoilMult = 12.0;     // Strength of kickback when firing
  static const double gunTiltMult = 0.18;       // How much the gun tilts up when firing
  static const Color gunFrameColor = Color(0xFF94A3B8);
  static const Color gunCylinderColor = Color(0xFF334155);
  static const Color gunGripColor = Color(0xFF78350F);

  // 🔱 SPEAR (Blade/Spear)
  static const double spearShaftLength = 2.1;   // Length of the wooden pole
  static const double spearThrustExt = 18.0;    // How far it lunges forward when attacking
  static const double spearHeadSize = 28.0;     // Size of the sharp point
  static const int spearTasselStrands = 4;      // Number of threads in the tassel
  static const double spearTasselWave = 12.0;   // How much the tassel waves
  static const Color spearShaftColor = Color(0xFF451A03);
  static const Color spearHeadColor = Color(0xFFCBD5E1);
  static const Color spearGripColor = Color(0xFF92400E);

  // 🏹 CROSSBOW (Laser/Crossbow)
  static const double crossbowStockLength = 22.0; // Length of the wooden body
  static const double crossbowLimbSpan = 28.0;   // How wide the bow arms are
  static const double crossbowStringPull = 12.0; // How far the string is pulled back
  static const double crossbowBoltLength = 32.0; // Length of the bolt (arrow)
  static const Color crossbowBodyColor = Color(0xFF451A03);
  static const Color crossbowLimbColor = Color(0xFF334155);

  // 🧨 MINER (TNT Dynamite)
  static const double tntStickWidth = 7.5;      // Thickness of each dynamite stick
  static const double tntStickHeight = 22.0;    // Length of each dynamite stick
  static const double tntShakeMult = 1.5;       // How much it vibrates
  static const double tntFuseLength = 14.0;     // Length of the fuse wire
  static const double tntSparkSize = 8.0;       // Size of the sparks on the fuse
  static const Color tntColor = AutoBattlePalette.primary;
  static const Color tntStrapColor = AutoBattlePalette.ink;
}

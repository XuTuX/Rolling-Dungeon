import 'package:circle_war/constant.dart';
import 'package:circle_war/controllers/score_controller.dart';
import 'package:circle_war/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:circle_war/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Home Logo Components ---

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 20,
            child: LogoBlock(color: regionColors[4], size: 60), // Blue
          ),
          Positioned(
            left: 10,
            top: 10,
            child: LogoBlock(color: regionColors[1], size: 60), // Orange
          ),
          Positioned(
            left: 0,
            top: 0,
            child: LogoBlock(color: regionColors[0], size: 60), // Red
          ),
        ],
      ),
    );
  }
}

class LogoBlock extends StatelessWidget {
  final Color color;
  final double size;

  const LogoBlock({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: charcoalBlack, width: 3),
      ),
    );
  }
}

// --- High Score Card ---

// --- High Score Card ---

class HighScoreCard extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const HighScoreCard({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nickname = authService.userNickname.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: charcoalBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: charcoalBlack,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'BEST SCORE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final isLoading = authService.isLoading.value ||
                      scoreController.isSyncing.value;

                  if (isLoading) {
                    return const SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: charcoalBlack,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    );
                  }

                  return Text(
                    '${scoreController.highscore.value}',
                    style: AppTypography.scoreDisplay,
                  );
                }),
              ],
            ),
          ),

          // Nickname Sticker Tag
          if (nickname != null)
            Positioned(
              top: -14,
              left: 16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: regionColors[2], // Yellow accent for "Post-it" look
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: charcoalBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: charcoalBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: charcoalBlack,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          nickname,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.blackHanSans(
                            fontSize: 16,
                            color: charcoalBlack,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// --- Buttons ---

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: regionColors[1], // Orange
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: GoogleFonts.blackHanSans(
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          side: BorderSide(color: borderColor, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Profile Button ---

class ProfileButton extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onProfileTap;
  final VoidCallback onLoginTap;

  const ProfileButton({
    super.key,
    required this.authService,
    required this.onProfileTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading spinner
      if (authService.isLoading.value) {
        return Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2),
        );
      }

      // Show success checkmark briefly after login
      if (authService.loginSuccess.value) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (value * 0.5),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        );
      }

      return GestureDetector(
        onTap: onProfileTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.black,
          ),
        ),
      );
    });
  }
}

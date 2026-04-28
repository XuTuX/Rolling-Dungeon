import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ad_service.dart';
import '../widgets/dialogs/custom_dialog.dart';
import '../constant.dart';
import '../theme/app_typography.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';
import '../controllers/theme_controller.dart';

import 'home_screen.dart';
import 'board.dart'; // Import Board widget

class GameOverDialog extends StatefulWidget {
  final VoidCallback onRestart;
  final Future<ContinueResult> Function()? onContinue;

  const GameOverDialog({
    super.key,
    required this.onRestart,
    this.onContinue,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  final GlobalKey _snapshotKey = GlobalKey();
  bool _isContinueLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _shareImage() async {
    try {
      HapticFeedback.mediumImpact();
      RenderRepaintBoundary? boundary = _snapshotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      // Small delay to ensure the widget is fully painted
      // (debugNeedsPaint is debug-only, so we always wait briefly)
      await Future.delayed(const Duration(milliseconds: 50));

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Create a new image with background color and padding for sharing
        final ThemeController themeController = Get.find<ThemeController>();
        final ui.Image capturedImage = await boundary.toImage(pixelRatio: 3.0);

        // Define padding for the shared image (in physical pixels)
        const int paddingPx = 80;
        final int newWidth = capturedImage.width + (paddingPx * 2);
        final int newHeight = capturedImage.height + (paddingPx * 2);

        // Start recording
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        // 1. Draw Background
        final Paint bgPaint = Paint()..color = themeController.backgroundColor;
        canvas.drawRect(
            Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
            bgPaint);

        // 2. Draw Captured Image Centered
        canvas.drawImage(capturedImage,
            Offset(paddingPx.toDouble(), paddingPx.toDouble()), Paint());

        // End recording and convert to image
        final ui.Image finalImage =
            await recorder.endRecording().toImage(newWidth, newHeight);

        final ByteData? finalByteData =
            await finalImage.toByteData(format: ui.ImageByteFormat.png);

        if (finalByteData == null) throw Exception('Failed to process image');

        final Uint8List pngBytes = finalByteData.buffer.asUint8List();
        final directory = await getTemporaryDirectory();
        final String fileName =
            'game_over_score_${DateTime.now().millisecondsSinceEpoch}.png';
        final File imgFile = File('${directory.path}/$fileName');
        await imgFile.writeAsBytes(pngBytes);

        // Get the share origin rect for iOS (required on iPad, helps on iPhone too)
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        final shareOrigin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imgFile.path, mimeType: 'image/png')],
          sharePositionOrigin: shareOrigin,
        );
      } else {
        throw Exception('Snapshot failed to capture data');
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        showCustomAlert('공유 실패', '이미지 공유에 실패했어요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are found
    final ScoreController scoreController = Get.find<ScoreController>();
    final ThemeController themeController = Get.find<ThemeController>();

    // Check high score
    final bool isHighScore = scoreController.hasNewHighScoreThisGame.value;

    // Use theme colors
    Color accentColor = themeController.textColor == Colors.white
        ? Colors.amberAccent
        : charcoalBlack;
    Color cardColor = themeController.backgroundColor == charcoalBlack
        ? Colors.grey[900]!
        : Colors.white;
    Color textColor = themeController.textColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Blur Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: charcoalBlack.withValues(alpha: 0.6),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isLandscape =
                        constraints.maxWidth > constraints.maxHeight;
                    bool isTablet =
                        MediaQuery.of(context).size.shortestSide >= 600;
                    final bool compact = constraints.maxHeight < 820;
                    final double horizontalMargin = isLandscape ? 20 : 16;
                    final double verticalMargin = isLandscape ? 16 : 12;
                    final double maxDialogHeight =
                        constraints.maxHeight - (verticalMargin * 2);

                    double dialogWidth;

                    if (isTablet) {
                      // iPad Design
                      dialogWidth = isLandscape
                          ? constraints.maxWidth * 0.5
                          : constraints.maxWidth * 0.55;
                      if (dialogWidth > 460) dialogWidth = 460;
                    } else {
                      // iPhone Design
                      dialogWidth = isLandscape
                          ? constraints.maxWidth * 0.8
                          : (constraints.maxWidth > 400
                              ? 360
                              : constraints.maxWidth * 0.9);
                    }

                    // If landscape, we might want a row layout
                    Widget content;
                    if (isLandscape && constraints.maxHeight < 600) {
                      content = _buildLandscapeLayout(
                        scoreController,
                        themeController,
                        isHighScore,
                        accentColor,
                        cardColor,
                        textColor,
                        dialogWidth,
                        maxDialogHeight,
                        compact,
                      );
                    } else {
                      content = _buildPortraitLayout(
                        scoreController,
                        themeController,
                        isHighScore,
                        accentColor,
                        cardColor,
                        textColor,
                        dialogWidth,
                        maxDialogHeight,
                        compact,
                      );
                    }

                    return Container(
                      width: dialogWidth,
                      height: maxDialogHeight,
                      margin: EdgeInsets.symmetric(
                        horizontal: horizontalMargin,
                        vertical: verticalMargin,
                      ),
                      child: content,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    ScoreController scoreController,
    ThemeController themeController,
    bool isHighScore,
    Color accentColor,
    Color cardColor,
    Color textColor,
    double width,
    double maxHeight,
    bool compact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildSnapshotCard(
            scoreController,
            themeController,
            isHighScore,
            accentColor,
            cardColor,
            textColor,
            compact: compact,
            maxBoardHeight: compact ? maxHeight * 0.3 : maxHeight * 0.36,
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        _buildActionButtons(accentColor, textColor, compact: compact),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    ScoreController scoreController,
    ThemeController themeController,
    bool isHighScore,
    Color accentColor,
    Color cardColor,
    Color textColor,
    double width,
    double maxHeight,
    bool compact,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _buildSnapshotCard(
            scoreController,
            themeController,
            isHighScore,
            accentColor,
            cardColor,
            textColor,
            compact: true,
            maxBoardHeight: maxHeight * 0.42,
          ),
        ),
        SizedBox(width: compact ? 16 : 24),
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: _buildActionButtons(accentColor, textColor, compact: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotCard(
    ScoreController scoreController,
    ThemeController themeController,
    bool isHighScore,
    Color accentColor,
    Color cardColor,
    Color textColor,
    {required bool compact,
    required double maxBoardHeight}
  ) {
    return RepaintBoundary(
      key: _snapshotKey,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 20),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: textColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: textColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: charcoalBlack.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
                color: accentColor,
                child: Text(
                  'MY SCORE',
                  textAlign: TextAlign.center,
                  style: AppTypography.title.copyWith(
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w900,
                    color: accentColor == charcoalBlack
                        ? Colors.white
                        : charcoalBlack,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Middle Section
              Expanded(
                child: Container(
                  color: cardColor,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 24,
                    compact ? 14 : 24,
                    compact ? 16 : 24,
                    compact ? 12 : 18,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxBoardHeight,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return AbsorbPointer(
                                    child: Board(
                                      gridSize: constraints.maxWidth,
                                      cellSize: constraints.maxWidth / gridColumns,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 18),
                      Text(
                        'FINAL SCORE',
                        style: AppTypography.label.copyWith(
                          color: textColor.withValues(alpha: 0.5),
                          letterSpacing: 2.0,
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${scoreController.score.value}',
                          style: AppTypography.scoreDisplay.copyWith(
                            color: textColor,
                            fontSize: compact ? 48 : null,
                          ),
                        ),
                      ),
                      if (isHighScore)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW BEST! 🏆',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: charcoalBlack,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          'Best: ${scoreController.highscore.value}',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Branding Footer — dark & visible
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 10 : 12,
                  horizontal: 16,
                ),
                color: charcoalBlack,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded,
                        size: 15, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'circle-war',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color accentColor, Color textColor,
      {required bool compact}) {
    final AdService adService = Get.find<AdService>();
    final double primaryButtonHeight = compact ? 48 : 56;
    final double continueButtonHeight = compact ? 54 : 64;
    final double secondaryButtonHeight = compact ? 46 : 52;
    final double gap = compact ? 12 : 16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Share Button (Prominent)
        GestureDetector(
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: _shareImage,
          child: Container(
            height: primaryButtonHeight,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: charcoalBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: charcoalBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'SHARE WITH FRIEND',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: gap),

        if (widget.onContinue != null)
          Obx(() {
            final bool isReady = adService.isRewardedAdReady.value;

            return Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: Opacity(
                opacity: _isContinueLoading ? 0.65 : 1,
                child: IgnorePointer(
                  ignoring: _isContinueLoading,
                  child: GestureDetector(
                    onTapDown: (_) => HapticFeedback.lightImpact(),
                    onTap: () async {
                      setState(() {
                        _isContinueLoading = true;
                      });

                      final result = await widget.onContinue!.call();
                      if (!mounted) return;

                      if (result == ContinueResult.success) {
                        Get.back();
                        return;
                      }

                      setState(() {
                        _isContinueLoading = false;
                      });

                      switch (result) {
                        case ContinueResult.alreadyUsed:
                          showCustomAlert(
                            '이어하기 완료',
                            '한 판당 이어하기는 한 번만 사용할 수 있어요.',
                          );
                          break;
                        case ContinueResult.noValidRegion:
                          showCustomAlert(
                            '이어하기 불가',
                            '지금 상태에서는 비워도 다시 놓을 수 있는 영역이 없어요.',
                          );
                          break;
                        case ContinueResult.adNotCompleted:
                          showCustomAlert(
                            '광고를 끝까지 봐야 해요',
                            '보상을 받으려면 광고를 끝까지 시청해야 해요.',
                          );
                          break;
                        case ContinueResult.adUnavailable:
                          showCustomAlert(
                            '광고 준비 중',
                            '조금 뒤에 다시 시도해주세요.',
                          );
                          break;
                        case ContinueResult.success:
                          break;
                      }
                    },
                    child: Container(
                      height: continueButtonHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF32C36C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: charcoalBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: charcoalBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isContinueLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(Icons.play_circle_fill_rounded,
                                color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _isContinueLoading
                                ? 'OPENING AD...'
                                : isReady
                                    ? 'WATCH AD TO CONTINUE'
                                    : 'AD LOADING...',
                            style: AppTypography.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                onPressed: () {
                  Get.offAll(() => const HomeScreen());
                },
                label: 'HOME',
                icon: Icons.home_rounded,
                backgroundColor: Colors.white,
                textColor: charcoalBlack,
                height: secondaryButtonHeight,
                compact: compact,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildSecondaryButton(
                onPressed: widget.onRestart,
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                backgroundColor: accentColor,
                textColor:
                    accentColor == charcoalBlack ? Colors.white : charcoalBlack,
                height: secondaryButtonHeight,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required double height,
    required bool compact,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: charcoalBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 14 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

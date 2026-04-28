import 'package:circle_war/config/app_config.dart';
import 'package:circle_war/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginSheet extends StatefulWidget {
  final bool isRankingAction;
  final String? initialError;
  final Future<String?> Function() onGoogleSignIn;
  final Future<String?> Function() onAppleSignIn;
  final VoidCallback? onLoginSuccess;

  const LoginSheet({
    super.key,
    this.isRankingAction = false,
    this.initialError,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
    this.onLoginSuccess,
  });

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  Future<void> _handleSignIn(Future<String?> Function() signInMethod) async {
    if (_isLoading) return; // 중복 탭 방지

    setState(() {
      _isLoading = true;
      _errorMessage = null; // 새 시도 시 에러 초기화
    });

    try {
      final error = await signInMethod();

      if (!mounted) return;

      if (error == null) {
        // 로그인 성공 → 시트 닫고 성공 콜백 실행
        Get.back();
        widget.onLoginSuccess?.call();
        return;
      } else if (error == 'cancelled') {
        // 사용자가 취소 → 로딩만 해제
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        // 에러 발생 → 에러 메시지 표시
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인에 실패했어요. 다시 시도해 주세요.';
        });
      }
      debugPrint('🔴 Sign-in error: $e');
    }
  }

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('🔴 Could not open URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              widget.isRankingAction ? '랭킹 참여' : '로그인',
                              textAlign: TextAlign.center,
                              style: AppTypography.title.copyWith(
                                fontSize: 24,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isRankingAction
                                  ? '로그인하면 랭킹에 참여할 수 있어요'
                                  : '로그인하면 기록 저장과 랭킹에\n참여할 수 있어요',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Inline error message (동적 업데이트)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: (_errorMessage != null &&
                                _errorMessage!.isNotEmpty)
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    left: 32, right: 32, top: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[400], size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 28),

                      // Sign-in Icon Buttons — circular, side by side
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Icon Button
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () =>
                                        _handleSignIn(widget.onGoogleSignIn),
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: _isLoading ? 0.3 : 1.0,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFDADCE0),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                          'assets/icons/google_logo.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (GetPlatform.isIOS) ...[
                                const SizedBox(width: 20),
                                // Apple Icon Button
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () =>
                                          _handleSignIn(widget.onAppleSignIn),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: _isLoading ? 0.3 : 1.0,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A1A1A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.apple,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_isLoading)
                            const Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Terms & Privacy
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _openUrl(AppConfig.termsOfServiceUrl),
                              child: Text(
                                '이용약관',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.grey[400],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                              child: Text(
                                '개인정보 처리방침',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:circle_war/constant.dart';
import 'package:circle_war/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:circle_war/utils/random_nickname_generator.dart';
import 'package:circle_war/services/database_service.dart';

class EditNicknameDialog extends StatefulWidget {
  final String currentNickname;
  final Future<String?> Function(String) onSave;
  final bool isInitialSetup;

  const EditNicknameDialog({
    super.key,
    required this.currentNickname,
    required this.onSave,
    this.isInitialSetup = false,
  });

  @override
  State<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<EditNicknameDialog> {
  late TextEditingController controller;
  String? errorMessage;
  bool isSaving = false;
  bool isGenerating =
      false; // Track if we are currently generating/verifying a random nick

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentNickname);

    if (widget.currentNickname.isEmpty) {
      _initRandomNickname();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _initRandomNickname() async {
    await _generateRandom();
  }

  Future<void> _generateRandom() async {
    if (isGenerating) return;

    setState(() {
      isGenerating = true;
      errorMessage = null;
    });

    final dbService = Get.find<DatabaseService>();
    String candidate = '';
    bool available = false;
    int attempts = 0;

    // Try up to 10 times to find a unique nickname
    while (attempts < 10 && !available) {
      candidate = RandomNicknameGenerator.generate();
      available = await dbService.checkNicknameAvailable(candidate);
      attempts++;
    }

    if (mounted) {
      setState(() {
        isGenerating = false;
        if (available) {
          controller.text = candidate;
        } else {
          errorMessage = '랜덤 닉네임 생성에 실패했습니다. 다시 시도해주세요.';
        }
      });
    }
  }

  Future<void> _handleSave() async {
    final newNick = controller.text.trim();
    if (newNick.isEmpty) {
      if (mounted) setState(() => errorMessage = '닉네임을 입력해주세요');
      return;
    }

    if (!widget.isInitialSetup && newNick == widget.currentNickname) {
      Get.back();
      return;
    }

    if (mounted) setState(() => isSaving = true);

    // No need for retry loop here anymore, as random nicks are pre-verified.
    // Manual entries are checked by the server update method.
    final error = await widget.onSave(newNick);

    if (mounted) {
      if (error != null) {
        setState(() {
          errorMessage = error;
          isSaving = false;
        });
      } else {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If it is initial setup, wrap with PopScope to prevent back button
    Widget dialogContent = Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: charcoalBlack, width: 3),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isInitialSetup ? '닉네임 설정' : '닉네임 변경',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: charcoalBlack,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: charcoalBlack, width: 2),
              ),
              child: TextField(
                controller: controller,
                style: AppTypography.body,
                onChanged: (_) {
                  if (errorMessage != null) {
                    setState(() => errorMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '새 닉네임',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: isGenerating
                      ? Transform.scale(
                          scale: 0.5,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: charcoalBlack,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: charcoalBlack),
                          tooltip: '랜덤 닉네임 생성',
                          onPressed: isGenerating ? null : _generateRandom,
                        ),
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (!widget.isInitialSetup) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF8F9FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: charcoalBlack, width: 2),
                          ),
                        ),
                        child: Text(
                          '취소',
                          style: AppTypography.button.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: charcoalBlack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              '저장',
                              style: AppTypography.button.copyWith(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.isInitialSetup) {
      return PopScope(
        canPop: false,
        child: dialogContent,
      );
    }
    return dialogContent;
  }
}

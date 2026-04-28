import 'package:circle_war/constant.dart';
import 'package:circle_war/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TutorialDialog extends StatefulWidget {
  final VoidCallback? onClose;
  const TutorialDialog({super.key, this.onClose});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': '블록 배치',
      'description': '블록을 보드 위로 드래그해서 배치하세요. \n블록 칸만큼 점수가 올라갑니다.',
    },
    {
      'title': '영역 채우기',
      'description': '색칠된 영역을 블록으로 모두 채우면 \n영역의 수에 따라 보너스 점수를 획득합니다.',
    },
    {
      'title': '콤보 보너스',
      'description': '여러 개의 영역을 동시에 완성하면 \n점수가 배수로 늘어나는 콤보가 발동됩니다.',
    },
    {
      'title': '게임 종료',
      'description': '더 이상 보드에 블록을 놓을 수 없게 되면 \n게임이 종료됩니다. 최대한 많은 영역을 차지해보세요!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Get.back();
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleClose();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: charcoalBlack, width: 3),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HOW TO PLAY',
                    style: AppTypography.label.copyWith(
                      fontSize: 14,
                      letterSpacing: 2.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: charcoalBlack, width: 2),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: charcoalBlack, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final item = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: regionColors[index % regionColors.length]
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    regionColors[index % regionColors.length],
                                width: 1.5),
                          ),
                          child: Text(
                            'STEP ${index + 1}',
                            style: AppTypography.label.copyWith(
                              fontSize: 12,
                              color: charcoalBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['title'],
                          style: AppTypography.title
                              .copyWith(fontSize: 24, height: 1.2),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['description'],
                          style: AppTypography.body.copyWith(
                            color: charcoalBlack87,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? charcoalBlack
                              : charcoalBlack.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 56,
                            child: TextButton(
                              onPressed: _prevPage,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: charcoalBlack.withValues(alpha: 0.1),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '이전',
                                style: AppTypography.button
                                    .copyWith(color: charcoalBlack),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: charcoalBlack,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _currentPage == _steps.length - 1 ? '시작하기' : '다음',
                              style: AppTypography.button
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notice_banner.dart';
import '../../feedback_data.dart';

/// Modal bottom sheet allowing beta users to submit usability feedback and report question issues.
///
/// INVARIANT: Does not collect, transmit, or record conversation answers or audio.
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({
    super.key,
    this.questionId,
    this.installationId,
    this.storage,
    this.onFeedbackSubmitted,
  });

  final String? questionId;
  final String? installationId;
  final FeedbackStorage? storage;
  final VoidCallback? onFeedbackSubmitted;

  static Future<void> show(
    BuildContext context, {
    String? questionId,
    String? installationId,
    FeedbackStorage? storage,
    VoidCallback? onFeedbackSubmitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: FeedbackSheet(
          questionId: questionId,
          installationId: installationId,
          storage: storage,
          onFeedbackSubmitted: onFeedbackSubmitted,
        ),
      ),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  late final TextEditingController _controller = TextEditingController();

  FeedbackCategory _category = FeedbackCategory.general;
  int _rating = 5;
  late bool _attachInstallationId = widget.installationId != null;
  bool _isSaving = false;
  String? _commentError;

  String get _ratingLabel => switch (_rating) {
    5 => 'ممتاز جدًا',
    4 => 'جيد جدًا',
    3 => 'جيد',
    2 => 'مقبول',
    _ => 'يحتاج تحسين',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitLocal() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) {
      setState(() {
        _commentError = 'يرجى كتابة ملاحظتك أو اقتراحك قبل الإرسال';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _commentError = null;
    });
    final report = FeedbackReport(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      category: _category,
      rating: _rating,
      comment: comment,
      questionId: widget.questionId,
      installationId: _attachInstallationId ? widget.installationId : null,
      createdAt: DateTime.now().toUtc(),
    );

    try {
      final directory = widget.storage == null
          ? await getApplicationSupportDirectory()
          : null;
      final storage =
          widget.storage ??
          FileFeedbackStorage(
            storageFile: File('${directory!.path}/feedback.json'),
          );
      await storage.saveFeedback(report);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ الملاحظة على الجهاز. حاول مرة أخرى.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    setState(() => _isSaving = false);
    widget.onFeedbackSubmitted?.call();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ ملاحظتك محليًا على جهازك فقط، ولم تُرسل.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _sendWhatsApp() {
    final comment = _controller.text.trim();
    if (comment.isEmpty) {
      setState(() {
        _commentError = 'يرجى كتابة ملاحظتك أو اقتراحك أولاً';
      });
      return;
    }

    final idSnippet = _attachInstallationId && widget.installationId != null
        ? '\nمعرّف التثبيت: ${widget.installationId}'
        : '';
    final questionSnippet = widget.questionId != null
        ? '\nبخصوص السؤال رقم: ${widget.questionId}'
        : '';

    final message =
        'ملاحظة تجريبية حول تطبيق وفاق:\n'
        'القسم: ${_category.label}\n'
        'التقييم: $_rating/5\n'
        'الملاحظة: $comment'
        '$questionSnippet$idSnippet';

    Navigator.of(context).pop();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إرسال الملاحظات للمطورين',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'راجع الملاحظة أدناه. لم يتم إرسالها؛ يمكنك نسخها وإرسالها بنفسك.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text(
              'نسخ الملاحظة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusHero + 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm + 2,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.chipBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.iconContainerGreen,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.rate_review_outlined,
                      color: AppColors.green,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.questionId != null
                            ? 'ملاحظة حول هذا السؤال'
                            : 'ملاحظات النسخة التجريبية',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              const Text(
                'نوع الملاحظة:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: FeedbackCategory.values.map((cat) {
                  final isSelected = cat == _category;
                  return ChoiceChip(
                    label: Text(
                      cat.label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.dark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.green,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.green
                          : AppColors.inputBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (val) {
                      if (val) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'تقييم التجربة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iconContainerGold,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      _ratingLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldText,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return Semantics(
                    selected: starNum <= _rating,
                    child: IconButton(
                      onPressed: () => setState(() => _rating = starNum),
                      icon: Icon(
                        starNum <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.goldText,
                        size: 30,
                      ),
                      tooltip: '$starNum من 5',
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 3,
                onChanged: (_) {
                  if (_commentError != null) {
                    setState(() => _commentError = null);
                  }
                },
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظتك، اقتراحك، أو أي استفسار بكل صراحة...',
                  errorText: _commentError,
                  hintStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: const BorderSide(
                      color: AppColors.green,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              if (widget.installationId != null) ...[
                const SizedBox(height: AppSpacing.xs),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.green,
                  value: _attachInstallationId,
                  onChanged: (val) =>
                      setState(() => _attachInstallationId = val ?? false),
                  title: const Text(
                    'تضمين معرّف التثبيت لمساعدة فريق الدعم في المتابعة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              const NoticeBanner(
                message: 'خصوصيتكم محفوظة: التطبيق لا يسجل إجاباتكم أو تفاصيل حواركم، والملاحظات هنا مخصصة لتجربة الاستخدام.',
                icon: Icons.shield_outlined,
                style: NoticeStyle.info,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _sendWhatsApp,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text(
                        'عبر واتساب',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submitLocal,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text(
                        'حفظ الملاحظة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

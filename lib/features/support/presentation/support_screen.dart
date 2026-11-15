import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notice_banner.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/wefaq_card.dart';
import '../../../../core/widgets/wefaq_page_header.dart';
import '../../licensing/licensing_data.dart';
import '../../feedback/presentation/widgets/feedback_sheet.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.licenseRepository});

  final LicenseRepository? licenseRepository;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  void _showWhatsAppDialog() {
    final template =
        'السلام عليكم، أحتاج مساعدة أو الاستفسار بخصوص تطبيق وفاق.';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'التواصل مع الدعم عبر واتساب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم تجهيز الرسالة التالية لإرسالها لخدمة العملاء:',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                template,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.dark,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'انسخ الرسالة ثم أرسلها بنفسك عند توفر وسيلة تواصل مناسبة.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: template));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ نص الرسالة للحافظة بنجاح.'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('نسخ الرسالة والمتابعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              WefaqPageHeader(
                leading: canPop
                    ? IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.surfaceWhite,
                        ),
                      )
                    : null,
                badgeText: 'دعم وخصوصية',
                title: AppStrings.supportTitle,
                subtitle: AppStrings.supportSubtitle,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 340;
                        final contactCard = WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.iconContainerGreen,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chat_outlined,
                                  color: AppColors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                AppStrings.contactSectionTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                AppStrings.supportWorkingHours,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _showWhatsAppDialog,
                                icon: const Icon(Icons.chat, size: 18),
                                label: const Text(
                                  AppStrings.openWhatsAppSupport,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final feedbackCard = WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.iconContainerGold,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.rate_review_outlined,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'ملاحظات وتقييم التجربة',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Text(
                                'رأيك وملاحظاتك تساهم بشكل مباشر في تحسين الأسئلة والأنشطة.',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => FeedbackSheet.show(context),
                                icon: const Icon(Icons.edit_note, size: 18),
                                label: const Text(
                                  'إرسال ملاحظة أو اقتراح',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isWide) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: contactCard),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: feedbackCard),
                              ],
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            contactCard,
                            const SizedBox(height: AppSpacing.md),
                            feedbackCard,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // FAQ Section Title
                    Text(
                      AppStrings.faqSectionTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // FAQ Items
                    _FaqAccordion(
                      question:
                          'هل التطبيق بيسجل إجاباتنا أو كلامنا في المكالمة؟',
                      answer: 'لا مطلقًا. التطبيق لا يطلب إذن الميكروفون، ولا يسجل أي صوت أو كتابة، وكل تفضيلاتك وجلساتك محفوظة محليًا على هاتفك فقط.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FaqAccordion(
                      question: 'إزاي بنستخدم التطبيق أثناء المكالمة الهاتفية؟',
                      answer: 'تفتحون المكالمة كالمعتاد عبر الهاتف أو أي تطبيق اتصال تفضلونه، ويقوم أحدكما بقراءة الأسئلة والأفكار من وفاق لفتح الحوار ومناقشته معًا.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FaqAccordion(
                      question: 'هل التطبيق يحتاج رمز تفعيل؟',
                      answer: 'لا، المميزات المتاحة مفتوحة دون رمز تفعيل.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FaqAccordion(
                      question: 'هل يحفظ التطبيق تقدمي عند إغلاقه؟',
                      answer: 'يُحفظ التقدم محليًا عند توفر مساحة التخزين. إنهاء الجلسة يحذف تقدمها.',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Privacy & Transparency Banner
                    const NoticeBanner(
                      message: AppStrings.privacyTermsSummaryBody,
                      icon: Icons.shield_outlined,
                      style: NoticeStyle.info,
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
}

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      color: AppColors.surfaceWhite,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        iconColor: AppColors.green,
        collapsedIconColor: AppColors.muted,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.0,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

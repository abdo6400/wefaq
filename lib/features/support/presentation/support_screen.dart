import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notice_banner.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/wefaq_card.dart';
import '../../../../core/widgets/wefaq_page_header.dart';
import '../../feedback/feedback_data.dart';
import '../../feedback/presentation/widgets/feedback_sheet.dart';
import '../../licensing/domain/repositories/offline_activation.dart';
import '../../licensing/licensing_data.dart';
import '../../licensing/presentation/offline_activation_gate.dart';
import '../../sessions/domain/repositories/question_updates.dart';
import '../../sessions/domain/repositories/session_storage.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({
    super.key,
    this.licenseRepository,
    this.activationService,
    this.questionUpdates,
    this.sessionStorage,
    this.appConfig,
    this.feedbackStorage,
    this.onSyncContent,
    this.onManageActivation,
  });

  final LicenseRepository? licenseRepository;
  final OfflineActivation? activationService;
  final QuestionUpdates? questionUpdates;
  final SessionStorage? sessionStorage;
  final AppConfig? appConfig;
  final FeedbackStorage? feedbackStorage;
  final Future<void> Function()? onSyncContent;
  final VoidCallback? onManageActivation;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _updating = false;
  ActivationState? _activationState;
  List<FeedbackReport> _savedFeedback = const [];

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    if (widget.activationService != null) {
      try {
        final st = await widget.activationService!.state();
        if (mounted) setState(() => _activationState = st);
      } catch (_) {}
    }
    if (widget.feedbackStorage != null) {
      try {
        final list = await widget.feedbackStorage!.getFeedbackReports();
        if (mounted) setState(() => _savedFeedback = list);
      } catch (_) {}
    }
  }

  Future<void> _updateQuestions() async {
    if (_updating) return;
    setState(() => _updating = true);
    String message;
    try {
      if (await widget.sessionStorage?.readActiveSession() != null) {
        message = AppStrings.updateHasSession;
      } else {
        final updated = await widget.questionUpdates!.update();
        if (widget.onSyncContent != null) {
          await widget.onSyncContent!();
        }
        message = updated ? AppStrings.updateSuccess : AppStrings.updateCurrent;
      }
    } catch (_) {
      message = AppStrings.updateFailed;
    }
    if (mounted) {
      setState(() => _updating = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showWhatsAppDialog() {
    final contact = widget.appConfig?.contact ?? const AppContactConfig();
    final instLine = _activationState != null
        ? '\nمعرّف التثبيت: ${_activationState!.installationId}'
        : '';
    final template = '${contact.contactMessageTemplate}$instLine';

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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                template,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.dark,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'انسخ الرسالة ثم أرسلها بنفسك عبر واتساب أو البريد (${contact.email}).',
              style: const TextStyle(
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

  void _showSavedFeedbackSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero + 4),
        ),
      ),
      builder: (ctx) {
        final maxSheetHeight = MediaQuery.sizeOf(ctx).height * 0.65;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.chipBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          AppStrings.savedFeedbackTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                        ),
                      ),
                    ),
                    if (_savedFeedback.isNotEmpty &&
                        widget.feedbackStorage != null)
                      TextButton(
                        onPressed: () async {
                          await widget.feedbackStorage!.clearAllFeedback();
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadExtras();
                        },
                        child: const Text(AppStrings.clearSavedFeedback),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'إغلاق',
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_savedFeedback.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        AppStrings.noSavedFeedback,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxSheetHeight),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _savedFeedback.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, index) {
                        final item = _savedFeedback.reversed.toList()[index];
                        return WefaqCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tagBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      item.category.label,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (item.rating != null)
                                    Text(
                                      '★ ${item.rating}/5',
                                      style: const TextStyle(
                                        color: AppColors.goldText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              Text(
                                item.comment,
                                style: const TextStyle(color: AppColors.dark),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final contact = widget.appConfig?.contact ?? const AppContactConfig();
    final feedbackEnabled = widget.appConfig?.features.feedbackEnabled ?? true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              WefaqPageHeader(
                compact: true,
                leading: canPop
                    ? IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
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
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.activationService != null &&
                        _activationState != null) ...[
                      WefaqCard(
                        hasShadow: true,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconContainerGreen,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppColors.green,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Text(
                                    AppStrings.activationCurrentLicense,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ),
                                if (_activationState!.license != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm + 2,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tagBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      _activationState!.remaining == null
                                          ? 'مفعل'
                                          : 'متبقي ${_activationState!.remaining}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  )
                                else if (_activationState!.isTrialActive(
                                  DateTime.now(),
                                ))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm + 2,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.iconContainerGold,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      'تجربة مجانية (${_activationState!.trialRemainingDays(DateTime.now()) ?? 1} يوم)',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldText,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_activationState!.license == null &&
                                _activationState!.isTrialActive(
                                  DateTime.now(),
                                )) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                AppStrings.activationTrialAutoCloseHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              AppStrings.installationIdLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: SelectableText(
                                _activationState!.installationId,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: _activationState!.installationId,
                                      ),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            AppStrings
                                                .installationIdCopiedMessage,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 17),
                                  label: const Text(
                                    AppStrings.copyInstallationIdButton,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (widget.onManageActivation != null) {
                                      widget.onManageActivation!();
                                    } else {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  OfflineActivationGate(
                                                    service: widget
                                                        .activationService!,
                                                    forceActivation: true,
                                                    contactConfig: contact,
                                                    child:
                                                        const SizedBox.shrink(),
                                                  ),
                                            ),
                                          )
                                          .then((_) => _loadExtras());
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      0,
                                      AppSpacing.minTouchTarget,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                  ),
                                  icon: const Icon(Icons.key, size: 17),
                                  label: const Text('إدارة التفعيل'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (widget.questionUpdates != null) ...[
                      WefaqCard(
                        hasShadow: true,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconContainerGreen,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.cloud_download_outlined,
                                    color: AppColors.green,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Text(
                                    AppStrings.updateQuestions,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.questionUpdates!.isConfigured
                                  ? AppStrings.updateQuestionsHint
                                  : AppStrings.updateUnconfigured,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed:
                                  _updating ||
                                      !widget.questionUpdates!.isConfigured
                                  ? null
                                  : _updateQuestions,
                              icon: const Icon(Icons.sync_rounded),
                              label: Text(
                                _updating
                                    ? AppStrings.updatingQuestions
                                    : AppStrings.updateQuestions,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= 460 && textScale <= 1.2;
                        final contactCard = WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
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
                                ],
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
                              Text(
                                contact.supportHours,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _showWhatsAppDialog,
                                icon: const Icon(Icons.chat, size: 18),
                                label: Text(
                                  contact.whatsappDisplay,
                                  style: const TextStyle(
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
                              Row(
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
                                      color: AppColors.goldText,
                                      size: 20,
                                    ),
                                  ),
                                ],
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
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => FeedbackSheet.show(
                                  context,
                                  installationId:
                                      _activationState?.installationId,
                                  storage: widget.feedbackStorage,
                                  onFeedbackSubmitted: _loadExtras,
                                ),
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
                              if (widget.feedbackStorage != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                TextButton(
                                  onPressed: _showSavedFeedbackSheet,
                                  child: Text(
                                    '${AppStrings.viewSavedFeedback} (${_savedFeedback.length})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );

                        if (!feedbackEnabled) return contactCard;
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
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.faqSectionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _FaqAccordion(
                      question:
                          'هل التطبيق بيسجل إجاباتنا أو كلامنا في المكالمة؟',
                      answer: 'لا مطلقًا. التطبيق لا يطلب إذن الميكروفون، ولا يسجل أي صوت أو كتابة، وكل تفضيلاتك وجلساتك محفوظة محليًا على هاتفك فقط.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _FaqAccordion(
                      question: 'إزاي بنستخدم التطبيق أثناء المكالمة الهاتفية؟',
                      answer: 'تفتحون المكالمة كالمعتاد عبر الهاتف أو أي تطبيق اتصال تفضلونه، ويقوم أحدكما بقراءة الأسئلة والأفكار من وفاق لفتح الحوار ومناقشته معًا.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FaqAccordion(
                      question: 'هل التطبيق يحتاج رمز تفعيل؟',
                      answer: widget.activationService != null
                          ? 'يعمل التطبيق مجانًا ودون إنترنت لمدة أسبوعين (14 يومًا) فور التثبيت، ثم يُغلق تلقائيًا حتى لو كان غير متصل بالإنترنت لحين إدخال كود أو رابط التفعيل المخصص لمعرّف التثبيت.'
                          : 'لا، المميزات المتاحة مفتوحة دون رمز تفعيل.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _FaqAccordion(
                      question: 'هل يحفظ التطبيق تقدمي عند إغلاقه؟',
                      answer: 'يُحفظ التقدم محليًا عند توفر مساحة التخزين. إنهاء الجلسة يحذف تقدمها.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
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
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

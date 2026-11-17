import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/wefaq_card.dart';
import '../../core/widgets/wefaq_page_header.dart';

// Original exploratory prompts, not a validated or licensed assessment.
const _prompts = <(String, List<String>)>[
  (
    'عندما تبدأ موضوعًا مهمًا، ما الذي تفضله؟',
    [
      'الدخول في النقطة مباشرة',
      'بدء الحديث بمشاركة الأفكار',
      'البدء بهدوء وإتاحة وقت للطرف الآخر',
      'فهم التفاصيل قبل الكلام',
    ],
  ),
  (
    'عندما تظهر مشكلة تحتاج قرارًا، ماذا يساعدك؟',
    [
      'تحديد خطوة عملية',
      'تبادل الاحتمالات مع الآخرين',
      'الاستماع لما يحتاجه كل طرف',
      'مراجعة المعلومات المتاحة',
    ],
  ),
  (
    'في ترتيب وقت مشترك، ما الذي تميل إليه؟',
    [
      'حسم خطة واضحة',
      'اقتراح تجربة جديدة',
      'اختيار وقت مريح للطرفين',
      'معرفة المواعيد والتفاصيل مسبقًا',
    ],
  ),
  (
    'عندما تختلف الآراء، ما الذي تفضله أولًا؟',
    [
      'التركيز على ما يمكن عمله',
      'فتح المجال لطرح أفكار متعددة',
      'الحفاظ على هدوء الحوار',
      'فهم أسباب كل رأي',
    ],
  ),
  (
    'عندما يشاركك أحد فكرة جديدة، ما أول ما تهتم به؟',
    [
      'النتيجة التي يمكن تحقيقها',
      'الفرص والأفكار التي تفتحها',
      'كيف ستؤثر على من حولنا',
      'التفاصيل والخطوات المطلوبة',
    ],
  ),
  (
    'كيف تحب التعامل مع تغيير غير متوقع؟',
    [
      'التحرك واختيار الخطوة التالية',
      'التفكير في فرص جديدة',
      'أخذ وقت للتأقلم بهدوء',
      'جمع معلومات قبل التصرف',
    ],
  ),
  (
    'عند العمل مع شخص آخر، ما الذي تقدره؟',
    [
      'وضوح الهدف والمسؤولية',
      'تبادل الأفكار بحماس',
      'التعاون والصبر',
      'الدقة والاتفاق على التفاصيل',
    ],
  ),
  (
    'عند مراجعة خطة، ما الذي تنتبه له؟',
    [
      'هل اقتربنا من الهدف؟',
      'هل توجد أفكار أخرى يمكن تجربتها؟',
      'هل الخطة مريحة للطرفين؟',
      'هل التفاصيل والموارد واضحة؟',
    ],
  ),
];
const _styles = [
  'D — المبادرة والإنجاز',
  'I — التفاعل وتبادل الأفكار',
  'S — الهدوء والتعاون',
  'C — الدقة ومراجعة التفاصيل',
];

const _styleDialogueTips = [
  'يميل لوضوح الهدف والخطوة العملية. يسعده الدخول في لب الموضوع مع الحفاظ على لطف الأسلوب.',
  'يميل للانفتاح والحماس وتبادل الأفكار. يسعده الشعور بالتقدير ومساحة التعبير الحر.',
  'يميل للسكينة والتدرج ومراعاة المشاعر. يسعده الاستماع الهادئ دون استعجال أو ضغط.',
  'يميل لفهم التفاصيل والتخطيط المسبق. يسعده وضوح التوقعات وإتاحة وقت للتفكير.',
];

const _optionLetters = ['أ', 'ب', 'ج', 'د'];

class DiscScreen extends StatefulWidget {
  const DiscScreen({super.key});
  @override
  State<DiscScreen> createState() => _DiscScreenState();
}

class _DiscScreenState extends State<DiscScreen> {
  int _index = -1;
  final List<int?> _answers = List.filled(_prompts.length, null);
  final List<String> _notes = List.filled(_prompts.length, '');
  final TextEditingController _controller = TextEditingController();
  bool _results = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => setState(() {
    _index = 0;
    _results = false;
  });

  void _changeQuestion(int index) {
    _notes[_index] = _controller.text;
    setState(() {
      _index = index;
      _controller.text = _notes[index];
    });
  }

  void _next() {
    if (_answers[_index] == null) return;
    _notes[_index] = _controller.text;
    if (_index + 1 < _prompts.length) {
      _changeQuestion(_index + 1);
    } else {
      setState(() => _results = true);
    }
  }

  Future<void> _exit() async {
    if (_index < 0 || _results) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.discExitTitle),
        content: const Text(AppStrings.discExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.discStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.discExit),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _copySummary(List<int> scores) async {
    final buffer = StringBuffer('ملخص تمرين استكشاف أسلوب الحوار (وفاق):\n');
    for (var i = 0; i < _styles.length; i++) {
      buffer.writeln('- ${_styles[i]}: ${scores[i]} / ${_prompts.length}');
    }
    buffer.write(
      '(تمرين تأملي غير تشخيصي لفتح الحوار فقط، بدون ملاحظات شخصية)',
    );
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ ملخص التمرين للمشاركة الهادئة.'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;

    return PopScope(
      canPop: _index < 0 || _results,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveContainer(
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                WefaqPageHeader(
                  compact: true,
                  leading: IconButton(
                    onPressed: _exit,
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  badgeText: _index >= 0 && !_results
                      ? 'السؤال ${_index + 1} من ${_prompts.length}'
                      : 'استكشاف شخصي',
                  title: AppStrings.discTitle,
                  subtitle: AppStrings.discPrivacy,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const NoticeBanner(
                        message: AppStrings.discDisclaimer,
                        icon: Icons.info_outline,
                        style: NoticeStyle.warning,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_index < 0)
                        WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExcludeSemantics(
                                child: Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconContainerGold,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE7D3AE),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.insights_outlined,
                                      color: AppColors.goldText,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'كل شخص يجاوب لنفسه ويختار الإجابة الأقرب له، ثم يمكنه مشاركة ما يحب في الحوار.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.dark,
                                      height: 1.65,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.xs + 2,
                                runSpacing: AppSpacing.xs + 2,
                                children: [
                                  _DiscFeaturePill(label: '8 أسئلة سريعة'),
                                  _DiscFeaturePill(label: 'ملاحظات مؤقتة'),
                                  _DiscFeaturePill(label: 'تُحذف عند الخروج'),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              FilledButton.icon(
                                onPressed: _start,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text(AppStrings.discStart),
                              ),
                            ],
                          ),
                        )
                      else if (_results)
                        ..._resultWidgets(context)
                      else
                        WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'السؤال ${_index + 1} من ${_prompts.length}',
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm + 2,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWarm,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      '${(((_index + 1) / _prompts.length) * 100).round()}%',
                                      style: const TextStyle(
                                        color: AppColors.goldText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    end: (_index + 1) / _prompts.length,
                                  ),
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) =>
                                      LinearProgressIndicator(
                                        value: value,
                                        minHeight: 8,
                                        backgroundColor:
                                            AppColors.progressTrack,
                                        color: AppColors.green,
                                        semanticsLabel:
                                            'السؤال ${_index + 1} من ${_prompts.length}',
                                      ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                _prompts[_index].$1,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.dark,
                                      fontWeight: FontWeight.bold,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              for (var i = 0; i < 4; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm + 2,
                                  ),
                                  child: Semantics(
                                    selected: _answers[_index] == i,
                                    inMutuallyExclusiveGroup: true,
                                    label:
                                        '${_optionLetters[i]}: ${_prompts[_index].$2[i]}',
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _answers[_index] = i),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _answers[_index] == i
                                            ? AppColors.tagBackground
                                            : AppColors.background,
                                        side: BorderSide(
                                          color: _answers[_index] == i
                                              ? AppColors.green
                                              : AppColors.inputBorder,
                                          width: _answers[_index] == i
                                              ? 1.5
                                              : 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusLg,
                                          ),
                                        ),
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                      ),
                                      child: ExcludeSemantics(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30,
                                              height: 30,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: _answers[_index] == i
                                                    ? AppColors.green
                                                    : AppColors.surfaceWhite,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _answers[_index] == i
                                                      ? AppColors.green
                                                      : AppColors.inputBorder,
                                                ),
                                              ),
                                              child: Text(
                                                _optionLetters[i],
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _answers[_index] == i
                                                      ? AppColors.surfaceWhite
                                                      : AppColors.dark,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Expanded(
                                              child: Text(
                                                _prompts[_index].$2[i],
                                                style: TextStyle(
                                                  color: AppColors.dark,
                                                  fontWeight:
                                                      _answers[_index] == i
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (_answers[_index] == i)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors.green,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _controller,
                                autocorrect: false,
                                enableSuggestions: false,
                                maxLines: 3,
                                maxLength: 500,
                                decoration: InputDecoration(
                                  labelText: AppStrings.discNote,
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.inputBorder,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: _answers[_index] == null
                                    ? null
                                    : _next,
                                child: Text(
                                  _index == _prompts.length - 1
                                      ? 'عرض النتيجة'
                                      : AppStrings.nextButton,
                                ),
                              ),
                              if (_index > 0) ...[
                                const SizedBox(height: AppSpacing.xs),
                                TextButton(
                                  onPressed: () => _changeQuestion(_index - 1),
                                  child: const Text(AppStrings.previousButton),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _resultWidgets(BuildContext context) {
    final scores = List<int>.filled(4, 0);
    for (final answer in _answers) {
      if (answer != null) scores[answer]++;
    }
    final highest = scores.reduce((a, b) => a > b ? a : b);
    return [
      WefaqCard(
        hasShadow: true,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.discResult,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < _styles.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scores[i] == highest
                        ? AppColors.surfaceWarm
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: scores[i] == highest
                          ? const Color(0xFFE4CFA8)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${_styles[i]}: ${scores[i]} ${scores[i] == highest ? '• من أعلى الاختيارات' : ''}',
                        style: TextStyle(
                          color: scores[i] == highest
                              ? AppColors.dark
                              : AppColors.muted,
                          fontWeight: scores[i] == highest
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: _prompts.isNotEmpty
                              ? scores[i] / _prompts.length
                              : 0,
                          minHeight: 8,
                          backgroundColor: AppColors.progressTrack,
                          color: scores[i] == highest
                              ? AppColors.goldText
                              : AppColors.green,
                          semanticsLabel:
                              '${_styles[i]}: ${scores[i]} من ${_prompts.length}',
                        ),
                      ),
                      if (scores[i] == highest) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            _styleDialogueTips[i],
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.dark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'النتيجة وصف لاختياراتك في هذا التمرين فقط، وقد تختلف باختلاف الموقف. استخدمها لفتح حوار عن احتياجاتك، لا لوصف شخصيتك أو الحكم على الآخرين.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => _copySummary(scores),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ ملخص النتيجة'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => setState(() {
                _answers.fillRange(0, _answers.length, null);
                _notes.fillRange(0, _notes.length, '');
                _controller.clear();
                _index = 0;
                _results = false;
              }),
              child: const Text(AppStrings.discAgain),
            ),
          ],
        ),
      ),
    ];
  }
}

class _DiscFeaturePill extends StatelessWidget {
  const _DiscFeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceTinted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
      ),
    );
  }
}

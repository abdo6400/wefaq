import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/wefaq_card.dart';
import '../../core/widgets/wefaq_page_header.dart';
import '../favorites/domain/repositories/favorites_storage.dart';
import 'presentation/widgets/choice_chips_selector.dart';
import 'presentation/widgets/setup_section.dart';
import 'session_data.dart';
import 'session_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({
    super.key,
    this.initialMode = ConversationMode.together,
    this.initialTopic = Topic.communication,
    this.repository,
    this.storage,
    this.favoritesStorage,
    this.historyStorage,
  });

  final ConversationMode initialMode;
  final Topic? initialTopic;
  final QuestionRepository? repository;
  final SessionStorage? storage;
  final FavoritesStorage? favoritesStorage;
  final QuestionHistoryStorage? historyStorage;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late ConversationMode mode = widget.initialMode;
  late Topic? topic = widget.initialTopic;
  Depth depth = Depth.introductory;
  int count = 3;
  late final QuestionRepository _repository =
      widget.repository ?? InMemoryQuestionRepository();

  List<Question> _available = [];
  int _loadGeneration = 0;
  bool _loading = true;
  bool _starting = false;
  bool _loadFailed = false;
  bool _avoidRepeats = false;
  int _totalMatching = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailable();
  }

  Future<void> _loadAvailable() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final result = await _repository.getQuestions(
        topic: topic,
        depth: depth,
        mode: mode,
      );
      final seen = _avoidRepeats && widget.historyStorage != null
          ? await widget.historyStorage!.getRecentlyAskedIds()
          : <String>{};
      final eligible = result.where((q) => !seen.contains(q.id)).toList();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _totalMatching = result.length;
        _available = eligible;
        if (eligible.isNotEmpty && count > eligible.length) {
          count = eligible.length;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _available = [];
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _onTopicChanged(Topic? value) {
    setState(() {
      topic = value;
      count = 1;
    });
    _loadAvailable();
  }

  void _onDepthChanged(Depth value) {
    setState(() {
      depth = value;
      count = 1;
    });
    _loadAvailable();
  }

  Future<void> _startSession() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final history = widget.historyStorage;
      final all = await _repository.getQuestions(
        topic: topic,
        depth: depth,
        mode: mode,
      );
      final seen = _avoidRepeats && history != null
          ? await history.getRecentlyAskedIds()
          : <String>{};
      final eligible = all.where((q) => !seen.contains(q.id)).toList()
        ..shuffle();
      if (!mounted) return;
      if (eligible.length < count) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عدد الأسئلة المتاحة تغيّر. راجع اختياراتك وحاول مجددًا.',
            ),
          ),
        );
        _loadAvailable();
        return;
      }
      final selected = eligible.take(count).toList();
      if (history != null) {
        await history.recordAskedQuestions(selected.map((q) => q.id).toList());
      }
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen.fromQuestions(
            items: selected,
            mode: mode,
            storage: widget.storage,
            favoritesStorage: widget.favoritesStorage,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر بدء الجلسة. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
        _loadAvailable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _available;
    final totalAvailable = questions.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360
        ? AppSpacing.lg
        : AppSpacing.xxl;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                WefaqPageHeader(
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  badgeText: '$count سؤال',
                  tagline: AppStrings.setupTitle,
                  title: AppStrings.setupHeader,
                  subtitle: AppStrings.setupSubheader,
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
                        message: AppStrings.sampleNoticeSetup,
                        icon: Icons.info_outline,
                        style: NoticeStyle.warning,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 340;
                          final modeCard = SetupSection(
                            icon: Icons.people_outline,
                            title: AppStrings.setupSectionMode,
                            child: ChoiceChipsSelector<ConversationMode>(
                              values: ConversationMode.values,
                              selected: mode,
                              label: (value) => value.label,
                              onChanged: (value) {
                                setState(() => mode = value);
                                _loadAvailable();
                              },
                            ),
                          );
                          final depthCard = SetupSection(
                            icon: Icons.tune,
                            title: AppStrings.setupSectionDepth,
                            child: ChoiceChipsSelector<Depth>(
                              values: Depth.values,
                              selected: depth,
                              label: (value) => value.label,
                              onChanged: _onDepthChanged,
                            ),
                          );
                          if (isWide) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: modeCard),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: depthCard),
                                ],
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              modeCard,
                              const SizedBox(height: AppSpacing.md),
                              depthCard,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SetupSection(
                        icon: Icons.category_outlined,
                        title: AppStrings.setupSectionTopic,
                        child: ChoiceChipsSelector<Topic?>(
                          values: [...Topic.values, null],
                          selected: topic,
                          label: (value) =>
                              value?.label ?? AppStrings.topicMixed,
                          onChanged: _onTopicChanged,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SetupSection(
                        icon: Icons.format_list_numbered,
                        title: AppStrings.setupSectionCount,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.quickCount,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final value in const [5, 10, 20, 30, 50])
                                  ChoiceChip(
                                    label: Text('$value'),
                                    selected: count == value,
                                    showCheckmark: false,
                                    selectedColor: AppColors.green,
                                    backgroundColor: AppColors.background,
                                    side: BorderSide(
                                      color: count == value
                                          ? AppColors.green
                                          : AppColors.chipBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color: count == value
                                          ? AppColors.surfaceWhite
                                          : AppColors.dark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected:
                                        !_loading && value <= totalAvailable
                                        ? (_) => setState(() => count = value)
                                        : null,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.sm,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                    border: Border.all(
                                      color: AppColors.chipBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: count > 1
                                            ? () => setState(() => count--)
                                            : null,
                                        tooltip:
                                            AppStrings.decreaseQuestionsTooltip,
                                        color: AppColors.green,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppColors.dark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: count < totalAvailable
                                            ? () => setState(() => count++)
                                            : null,
                                        tooltip:
                                            AppStrings.increaseQuestionsTooltip,
                                        color: AppColors.green,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tagBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    '${AppStrings.availableCountPrefix} $totalAvailable',
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SetupSection(
                        icon: Icons.history_rounded,
                        title: AppStrings.newQuestionsTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  AppStrings.avoidPreviousQuestions,
                                ),
                                value: _avoidRepeats,
                                onChanged: widget.historyStorage == null
                                    ? null
                                    : (value) {
                                        setState(() => _avoidRepeats = value);
                                        _loadAvailable();
                                      },
                              ),
                            ),
                            Text(
                              widget.historyStorage == null
                                  ? AppStrings.historyUnavailable
                                  : AppStrings.historyExplanation,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (_avoidRepeats && !_loading && !_loadFailed)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Text(
                                  AppStrings.newQuestionCount(
                                    totalAvailable,
                                    _totalMatching,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (mode == ConversationMode.phone)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: NoticeBanner(
                            message: AppStrings.phoneNotice,
                            icon: Icons.phone_outlined,
                            style: NoticeStyle.info,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      WefaqCard(
                        hasShadow: true,
                        backgroundColor: AppColors.tagBackground,
                        borderColor: AppColors.chipBorder,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_loading)
                              const Center(child: CircularProgressIndicator())
                            else if (_loadFailed)
                              TextButton(
                                onPressed: _loadAvailable,
                                child: const Text(
                                  'تعذر تحميل الأسئلة. اضغط لإعادة المحاولة.',
                                ),
                              )
                            else if (totalAvailable == 0)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  _avoidRepeats
                                      ? AppStrings.noNewQuestions
                                      : 'لا توجد أسئلة متاحة لهذه الاختيارات.',
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            FilledButton.icon(
                              onPressed:
                                  !_loading && !_starting && totalAvailable > 0
                                  ? () => _startSession()
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text(AppStrings.startSessionButton),
                            ),
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
}

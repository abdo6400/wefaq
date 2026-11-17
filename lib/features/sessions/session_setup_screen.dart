import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/wefaq_card.dart';
import '../../core/widgets/wefaq_page_header.dart';
import '../../core/widgets/wefaq_shimmer.dart';
import '../favorites/domain/repositories/favorites_storage.dart';
import '../licensing/domain/repositories/offline_activation.dart';
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
    this.activationService,
  });

  final ConversationMode initialMode;
  final Topic? initialTopic;
  final QuestionRepository? repository;
  final SessionStorage? storage;
  final FavoritesStorage? favoritesStorage;
  final QuestionHistoryStorage? historyStorage;
  final OfflineActivation? activationService;

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
  bool _pendingStart = false;
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
        if (eligible.isNotEmpty) {
          if (count > eligible.length) {
            count = eligible.length;
          } else if (count < 1) {
            count = min(3, eligible.length);
          }
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
    });
    _loadAvailable();
  }

  void _onDepthChanged(Depth value) {
    setState(() {
      depth = value;
    });
    _loadAvailable();
  }

  IconData _topicIcon(Topic? value) => switch (value) {
    Topic.communication => Icons.forum_outlined,
    Topic.dailyLife => Icons.wb_sunny_outlined,
    Topic.familyRelations => Icons.home_outlined,
    Topic.finances => Icons.account_balance_wallet_outlined,
    Topic.coreValues => Icons.auto_awesome_outlined,
    null => Icons.shuffle_rounded,
  };

  Future<void> _startSession() async {
    if (_starting || _pendingStart) return;
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
      String? sessionId;
      if (widget.activationService != null) {
        final licenseState = await widget.activationService!.state();
        final now = DateTime.now();
        if (!licenseState.canStartSession(now)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  licenseState.license == null
                      ? 'انتهت الفترة التجريبية المجانية (14 يومًا). فعّل التطبيق للمتابعة.'
                      : 'انتهت صلاحية الاشتراك أو رصيد الجلسات. استخدم إدارة التفعيل لتجديده.',
                ),
              ),
            );
          }
          return;
        }
        final random = Random.secure();
        final hex = List<int>.generate(
          16,
          (_) => random.nextInt(256),
        ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        if (licenseState.license != null) {
          final store = widget.storage;
          if (store == null) {
            throw StateError('Persistent session storage required');
          }
          sessionId = 'licensed-$hex';
          await store.writeActiveSession(
            SavedSessionState(
              sessionId: sessionId,
              questionIds: selected.map((q) => q.id).toList(),
              mode: mode,
              currentIndex: 0,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
          _pendingStart = true;
          if (!await widget.activationService!.reserve(sessionId)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تعذر بدء الجلسة. ارجع للرئيسية لاستعادتها أو حذفها.',
                  ),
                ),
              );
            }
            return;
          }
        } else {
          sessionId = 'trial-$hex';
        }
      }
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
            sessionId: sessionId,
          ),
        ),
      );
      _pendingStart = false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pendingStart
                  ? 'تعذر إكمال البدء. ارجع للرئيسية لاستعادة الجلسة المحفوظة.'
                  : 'تعذر بدء الجلسة. حاول مرة أخرى.',
            ),
          ),
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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;
    final theme = Theme.of(context);
    final canStart =
        !_loading && !_starting && !_pendingStart && totalAvailable > 0;

    return Scaffold(
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.md,
                  horizontalPadding,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${mode.label} · ${topic?.label ?? AppStrings.topicMixed} · ${depth.label}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                            '$count سؤال',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    FilledButton.icon(
                      onPressed: canStart ? () => _startSession() : null,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surfaceWhite,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text(AppStrings.startSessionButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                WefaqPageHeader(
                  compact: true,
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
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
                          final isWide =
                              constraints.maxWidth >= 460 && textScale <= 1.2;
                          final modeCard = SetupSection(
                            icon: Icons.people_outline,
                            title: AppStrings.setupSectionMode,
                            child: ChoiceChipsSelector<ConversationMode>(
                              values: ConversationMode.values,
                              selected: mode,
                              label: (value) => value.label,
                              iconBuilder: (value) =>
                                  value == ConversationMode.together
                                  ? Icons.people_outline
                                  : Icons.phone_outlined,
                              onChanged: (value) {
                                setState(() => mode = value);
                                _loadAvailable();
                              },
                            ),
                          );
                          final depthCard = SetupSection(
                            icon: Icons.tune_rounded,
                            title: AppStrings.setupSectionDepth,
                            child: ChoiceChipsSelector<Depth>(
                              values: Depth.values,
                              selected: depth,
                              label: (value) => value.label,
                              iconBuilder: (value) =>
                                  value == Depth.introductory
                                  ? Icons.wb_twilight_rounded
                                  : Icons.psychology_outlined,
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
                          iconBuilder: _topicIcon,
                          onChanged: _onTopicChanged,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SetupSection(
                        icon: Icons.format_list_numbered_rounded,
                        title: AppStrings.setupSectionCount,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 1,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.quickCount,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    side: BorderSide(
                                      color: count == value
                                          ? AppColors.green
                                          : AppColors.inputBorder,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: count > 1
                                        ? () => setState(() => count--)
                                        : null,
                                    tooltip:
                                        AppStrings.decreaseQuestionsTooltip,
                                    color: AppColors.green,
                                    icon: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                    ),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      liveRegion: true,
                                      label: 'عدد الأسئلة المختار: $count',
                                      child: ExcludeSemantics(
                                        child: Text(
                                          '$count',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                color: AppColors.dark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
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
                                      Icons.add_circle_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
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
                                activeThumbColor: AppColors.green,
                                title: const Text(
                                  AppStrings.avoidPreviousQuestions,
                                  style: TextStyle(fontWeight: FontWeight.w700),
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                            if (_avoidRepeats && !_loading && !_loadFailed)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs + 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tagBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.newQuestionCount(
                                      totalAvailable,
                                      _totalMatching,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            isLiveRegion: true,
                          ),
                        ),
                      if (_loading)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Semantics(
                            label: 'جارٍ تحميل الأسئلة المتاحة',
                            child: const WefaqInlineShimmer(height: 24),
                          ),
                        )
                      else if (_loadFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: WefaqCard(
                            backgroundColor: AppColors.surfaceWarm,
                            borderColor: AppColors.gold,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: TextButton.icon(
                              onPressed: _loadAvailable,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'تعذر تحميل الأسئلة. اضغط لإعادة المحاولة.',
                              ),
                            ),
                          ),
                        )
                      else if (totalAvailable == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: NoticeBanner(
                            message: _avoidRepeats
                                ? AppStrings.noNewQuestions
                                : 'لا توجد أسئلة متاحة لهذه الاختيارات.',
                            icon: Icons.filter_alt_off_outlined,
                            style: NoticeStyle.warning,
                            isLiveRegion: true,
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

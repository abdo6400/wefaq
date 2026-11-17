import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/wefaq_card.dart';
import '../../core/widgets/wefaq_page_header.dart';
import '../activities/activity_data.dart';
import '../favorites/data/favorites_storage.dart';
import '../favorites/domain/repositories/favorites_storage.dart';
import '../favorites/presentation/favorites_screen.dart';
import '../feedback/feedback_data.dart';
import '../feedback/presentation/widgets/feedback_sheet.dart';
import '../licensing/domain/repositories/offline_activation.dart';
import '../licensing/licensing_data.dart';
import '../licensing/presentation/offline_activation_gate.dart';
import '../sessions/domain/repositories/question_updates.dart';
import '../sessions/presentation/widgets/question_dialogue_card.dart';
import '../sessions/session_data.dart';
import '../sessions/session_screen.dart';
import '../sessions/session_setup_screen.dart';
import '../support/support_data.dart';
import 'presentation/widgets/mode_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.sessionStorage,
    this.questionRepository,
    this.favoritesStorage,
    this.historyStorage,
    this.licenseRepository,
    this.activationService,
    this.questionUpdates,
    this.activityRepository,
    this.appConfigRepository,
    this.feedbackStorage,
    this.onSyncContent,
  });

  final SessionStorage? sessionStorage;
  final QuestionRepository? questionRepository;
  final FavoritesStorage? favoritesStorage;
  final QuestionHistoryStorage? historyStorage;
  final LicenseRepository? licenseRepository;
  final OfflineActivation? activationService;
  final QuestionUpdates? questionUpdates;
  final ActivityRepository? activityRepository;
  final AppConfigRepository? appConfigRepository;
  final FeedbackStorage? feedbackStorage;
  final Future<void> Function()? onSyncContent;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final SessionStorage _sessionStorage =
      widget.sessionStorage ?? InMemorySessionStorage();
  late final QuestionRepository _questionRepository =
      widget.questionRepository ?? JsonAssetQuestionRepository();
  late final FavoritesStorage _favoritesStorage =
      widget.favoritesStorage ?? InMemoryFavoritesStorage();
  late final QuestionHistoryStorage _historyStorage =
      widget.historyStorage ?? InMemoryQuestionHistoryStorage();

  int _selectedTab = 0;
  SavedSessionState? _savedSession;
  bool _sessionReadFailed = false;
  Map<Topic, int> _topicCounts = {};
  int _totalQuestionsCount = 0;
  int _countGeneration = 0;
  AppConfig _appConfig = AppConfig.defaults;
  ActivationState? _activationState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSavedSession();
    _refreshQuestionCounts();
    _loadAppConfig();
    _loadActivationState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadActivationState();
    }
  }

  Future<void> _loadAppConfig() async {
    final repo = widget.appConfigRepository;
    if (repo == null) return;
    try {
      final cached = await repo.getConfig();
      if (mounted) setState(() => _appConfig = cached);
      if (repo.isConfigured) {
        final updated = await repo.refresh();
        if (updated && mounted) {
          final fresh = await repo.getConfig();
          if (mounted) setState(() => _appConfig = fresh);
        }
      }
    } catch (_) {
      // Keep default/cached app config safely offline.
    }
  }

  Future<void> _loadActivationState() async {
    if (widget.activationService == null) return;
    try {
      final st = await widget.activationService!.state();
      if (mounted) setState(() => _activationState = st);
    } catch (_) {}
  }

  Future<void> _refreshQuestionCounts() async {
    final generation = ++_countGeneration;
    try {
      final counts = <Topic, int>{for (final topic in Topic.values) topic: 0};
      var total = 0;
      for (final depth in Depth.values) {
        for (final question in await _questionRepository.getQuestions(
          depth: depth,
        )) {
          counts.update(
            question.topic,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          total++;
        }
      }
      if (mounted && generation == _countGeneration) {
        setState(() {
          _topicCounts = counts;
          _totalQuestionsCount = total;
        });
      }
    } catch (_) {
      if (mounted && generation == _countGeneration) {
        setState(() {
          _topicCounts = {};
          _totalQuestionsCount = 0;
        });
      }
    }
  }

  String _topicBadge(Topic topic) => _topicCounts.containsKey(topic)
      ? '${_topicCounts[topic]} سؤال'
      : 'اكتشف الأسئلة';

  Future<void> _checkSavedSession() async {
    SavedSessionState? saved;
    try {
      saved = await _sessionStorage.readActiveSession();
    } catch (_) {
      if (mounted) {
        setState(() => _sessionReadFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر قراءة الجلسة المحفوظة. لم يتم حذف بياناتها.'),
          ),
        );
      }
      return;
    }
    if (mounted) {
      setState(() {
        _savedSession = saved;
        _sessionReadFailed = false;
      });
    }
  }

  Future<void> _discardSavedSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.discardDialogTitle),
        content: const Text(AppStrings.discardDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.discardConfirmAction),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sessionStorage.clearActiveSession();
      if (mounted) {
        setState(() => _savedSession = null);
      }
    }
  }

  Future<void> _resumeSession() async {
    final saved = _savedSession;
    if (saved == null) return;

    final all = <Question>[];
    for (final depth in Depth.values) {
      all.addAll(await _questionRepository.getQuestions(depth: depth));
    }
    if (!mounted) return;
    final idToQuestion = {for (final q in all) q.id: q};
    if (saved.questionIds.any((id) => !idToQuestion.containsKey(id))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر استعادة الجلسة لأن بعض الأسئلة غير متاحة.'),
        ),
      );
      return;
    }

    final resumedItems = [
      for (final id in saved.questionIds) idToQuestion[id]!,
    ];

    if (resumedItems.isEmpty) {
      await _sessionStorage.clearActiveSession();
      if (mounted) setState(() => _savedSession = null);
      return;
    }

    if (widget.activationService != null) {
      try {
        if (saved.sessionId.startsWith('licensed-')) {
          if (!await widget.activationService!.reserve(saved.sessionId)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تعذر بدء الجلسة: انتهت صلاحية الاشتراك أو رصيد الجلسات.',
                  ),
                ),
              );
            }
            return;
          }
        } else {
          final currentState = await widget.activationService!.state();
          if (!currentState.hasAccess(DateTime.now())) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'انتهت الفترة التجريبية المجانية. فعّل التطبيق لاستئناف الجلسة.',
                  ),
                ),
              );
            }
            return;
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر التحقق من التفعيل. الجلسة محفوظة، حاول مرة أخرى.',
              ),
            ),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    try {
      await _historyStorage.recordAskedQuestions(saved.questionIds);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resumeHistoryFailure)),
        );
      }
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen.fromQuestions(
          items: resumedItems,
          mode: saved.mode,
          initialIndex: saved.currentIndex,
          initialSkipped: saved.skippedIndices,
          storage: _sessionStorage,
          favoritesStorage: _favoritesStorage,
          sessionId: saved.sessionId,
        ),
      ),
    );

    _checkSavedSession();
    _loadActivationState();
  }

  Future<void> _openSetup([
    ConversationMode mode = ConversationMode.together,
    Topic? topic,
    bool allowMixedTopic = false,
  ]) async {
    if (_sessionReadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر قراءة الجلسة السابقة؛ لم يتم حذفها.'),
        ),
      );
      return;
    }
    if (_savedSession != null) {
      await _discardSavedSession();
      if (!mounted || _savedSession != null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionSetupScreen(
          initialMode: mode,
          initialTopic: allowMixedTopic
              ? topic
              : (topic ?? Topic.communication),
          repository: _questionRepository,
          storage: _sessionStorage,
          favoritesStorage: _favoritesStorage,
          historyStorage: _historyStorage,
          activationService: widget.activationService,
        ),
      ),
    );
    _checkSavedSession();
    _loadActivationState();
  }

  void _openActivationManagement() {
    if (widget.activationService == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => OfflineActivationGate(
              service: widget.activationService!,
              forceActivation: true,
              contactConfig: _appConfig.contact,
              child: const SizedBox.shrink(),
            ),
          ),
        )
        .then((_) => _loadActivationState());
  }

  Future<void> _showQuickSpark() async {
    final all = <Question>[];
    for (final depth in Depth.values) {
      all.addAll(await _questionRepository.getQuestions(depth: depth));
    }
    if (!mounted || all.isEmpty) return;

    final random = Random();
    Topic? selectedTopic;
    List<Question> pool() => selectedTopic == null
        ? all
        : all.where((q) => q.topic == selectedTopic).toList();

    var current = all[random.nextInt(all.length)];
    var isFav = await _favoritesStorage.isFavorite(current.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero + 4),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
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
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.iconContainerGold,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.goldText,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'سؤال سريع للحوار',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      tooltip: 'إغلاق',
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('الكل'),
                        selected: selectedTopic == null,
                        showCheckmark: false,
                        selectedColor: AppColors.green,
                        backgroundColor: AppColors.surfaceWhite,
                        side: BorderSide(
                          color: selectedTopic == null
                              ? AppColors.green
                              : AppColors.inputBorder,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectedTopic == null
                              ? AppColors.surfaceWhite
                              : AppColors.dark,
                        ),
                        onSelected: (_) async {
                          selectedTopic = null;
                          final items = pool();
                          final next = items[random.nextInt(items.length)];
                          final nextFav = await _favoritesStorage.isFavorite(
                            next.id,
                          );
                          setModalState(() {
                            current = next;
                            isFav = nextFav;
                          });
                        },
                      ),
                      for (final topic in Topic.values) ...[
                        const SizedBox(width: AppSpacing.xs + 2),
                        ChoiceChip(
                          label: Text(topic.label),
                          selected: selectedTopic == topic,
                          showCheckmark: false,
                          selectedColor: AppColors.green,
                          backgroundColor: AppColors.surfaceWhite,
                          side: BorderSide(
                            color: selectedTopic == topic
                                ? AppColors.green
                                : AppColors.inputBorder,
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedTopic == topic
                                ? AppColors.surfaceWhite
                                : AppColors.dark,
                          ),
                          onSelected: (_) async {
                            selectedTopic = topic;
                            final items = pool();
                            if (items.isEmpty) return;
                            final next = items[random.nextInt(items.length)];
                            final nextFav = await _favoritesStorage.isFavorite(
                              next.id,
                            );
                            setModalState(() {
                              current = next;
                              isFav = nextFav;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: QuestionDialogueCard(
                    key: ValueKey(current.id),
                    questionText: current.text,
                    clarificationText: current.clarification,
                    topicLabel: current.topic.label,
                    depthLabel: current.depth.label,
                    isFavorite: isFav,
                    onFavoriteToggle: () async {
                      final updated = await _favoritesStorage.toggleFavorite(
                        current.id,
                      );
                      setModalState(() => isFav = updated);
                    },
                    onCopyQuestion: () async {
                      await Clipboard.setData(
                        ClipboardData(text: current.text),
                      );
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.questionCopiedMessage),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      }
                    },
                    onReportQuestion: () => FeedbackSheet.show(
                      context,
                      questionId: current.id,
                      storage: widget.feedbackStorage,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final items = pool();
                          if (items.isEmpty) return;
                          final next = items[random.nextInt(items.length)];
                          final nextFav = await _favoritesStorage.isFavorite(
                            next.id,
                          );
                          setModalState(() {
                            current = next;
                            isFav = nextFav;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('سؤال عشوائي آخر'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openSetup(
                            ConversationMode.together,
                            selectedTopic ?? current.topic,
                          );
                        },
                        child: const Text('جلسة في المحور'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;
    final announcement = _appConfig.announcement;
    final features = _appConfig.features;

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
        child: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) {
            setState(() => _selectedTab = index);
            if (index == 0) {
              _refreshQuestionCounts();
              _loadActivationState();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style_rounded),
              label: AppStrings.navPlay,
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border_rounded),
              selectedIcon: Icon(Icons.star_rounded),
              label: AppStrings.navFavorites,
            ),
            NavigationDestination(
              icon: Icon(Icons.help_outline_rounded),
              selectedIcon: Icon(Icons.help_rounded),
              label: AppStrings.navHelp,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey(_selectedTab),
          child: switch (_selectedTab) {
            0 => SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    children: [
                      WefaqPageHeader(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd + 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.cardShadowDeep,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  child: Image.asset(
                                    'assets/images/wefaq_icon_concept.png',
                                    width: 34,
                                    height: 34,
                                    semanticLabel: AppStrings.appLogoSemantics,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Text(
                              AppStrings.appName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        badgeText: _totalQuestionsCount > 0
                            ? '$_totalQuestionsCount سؤال'
                            : null,
                        tagline: AppStrings.heroSubtitle,
                        title: AppStrings.welcomeTitle,
                        subtitle: AppStrings.heroDescription,
                        bottomOverlap: 20,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: WefaqCard(
                                hasShadow: true,
                                padding: const EdgeInsets.all(
                                  AppSpacing.md + 2,
                                ),
                                borderRadius: AppSpacing.radiusCard + 2,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 320;
                                    final primaryBtn = FilledButton.icon(
                                      onPressed: _openSetup,
                                      icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 19,
                                      ),
                                      label: const Text(
                                        AppStrings.startConversation,
                                      ),
                                    );
                                    final sparkBtn = OutlinedButton.icon(
                                      onPressed: _showQuickSpark,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceWarm,
                                        foregroundColor: AppColors.dark,
                                        side: const BorderSide(
                                          color: Color(0xFFD8B87E),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: AppColors.goldText,
                                      ),
                                      label: const Text('سؤال سريع'),
                                    );
                                    if (!features.quickSparkEnabled) {
                                      return primaryBtn;
                                    }
                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Expanded(flex: 3, child: primaryBtn),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(flex: 2, child: sparkBtn),
                                        ],
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        primaryBtn,
                                        const SizedBox(height: AppSpacing.sm),
                                        sparkBtn,
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (announcement.enabled &&
                                announcement.message.isNotEmpty) ...[
                              NoticeBanner(
                                message: announcement.title.isNotEmpty
                                    ? '${announcement.title}: ${announcement.message}'
                                    : announcement.message,
                                icon:
                                    announcement.style ==
                                        AnnouncementStyle.warning
                                    ? Icons.campaign_outlined
                                    : Icons.notifications_active_outlined,
                                style:
                                    announcement.style ==
                                        AnnouncementStyle.warning
                                    ? NoticeStyle.warning
                                    : NoticeStyle.info,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (widget.activationService != null) ...[
                              _LicenseBarCard(
                                activationState: _activationState,
                                onManage: _openActivationManagement,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (_savedSession != null) ...[
                              _SavedSessionCard(
                                savedSession: _savedSession!,
                                onResume: _resumeSession,
                                onDiscard: _discardSavedSession,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            const _SectionHeader(
                              title: AppStrings.chooseModeSectionTitle,
                              subtitle: AppStrings.chooseModeSectionSubtitle,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ModeGridTile(
                                      icon: Icons.people_outline_rounded,
                                      title: AppStrings.modeTogetherTitle,
                                      subtitle: AppStrings.modeTogetherSubtitle,
                                      onTap: () =>
                                          _openSetup(ConversationMode.together),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ModeGridTile(
                                      icon: Icons.phone_in_talk_outlined,
                                      title: AppStrings.modePhoneTitle,
                                      subtitle: AppStrings.modePhoneSubtitle,
                                      isGoldAccent: true,
                                      onTap: () =>
                                          _openSetup(ConversationMode.phone),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const _SectionHeader(
                              title: 'تصفح المحاور مباشرة',
                              subtitle:
                                  'ابدأ جلسة مركزة في الموضوع الذي يهمكما الآن',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon: Icons.forum_outlined,
                                      title: Topic.communication.label,
                                      countBadge: _topicBadge(
                                        Topic.communication,
                                      ),
                                      accentColor: AppColors.green,
                                      accentBackground:
                                          AppColors.iconContainerGreen,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        Topic.communication,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon: Icons.wb_sunny_outlined,
                                      title: Topic.dailyLife.label,
                                      countBadge: _topicBadge(Topic.dailyLife),
                                      accentColor: AppColors.topicTeal,
                                      accentBackground: AppColors.topicTealBg,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        Topic.dailyLife,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon: Icons.home_outlined,
                                      title: Topic.familyRelations.label,
                                      countBadge: _topicBadge(
                                        Topic.familyRelations,
                                      ),
                                      accentColor: AppColors.topicSage,
                                      accentBackground: AppColors.topicSageBg,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        Topic.familyRelations,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      title: Topic.finances.label,
                                      countBadge: _topicBadge(Topic.finances),
                                      accentColor: AppColors.topicBronze,
                                      accentBackground: AppColors.topicBronzeBg,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        Topic.finances,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon: Icons.auto_awesome_outlined,
                                      title: Topic.coreValues.label,
                                      countBadge: _topicBadge(Topic.coreValues),
                                      accentColor: AppColors.topicTerracotta,
                                      accentBackground:
                                          AppColors.topicTerracottaBg,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        Topic.coreValues,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TopicBentoTile(
                                      icon: Icons.shuffle_rounded,
                                      title: AppStrings.topicMixed,
                                      countBadge: _totalQuestionsCount > 0
                                          ? '$_totalQuestionsCount سؤال'
                                          : 'متنوع',
                                      isGoldAccent: true,
                                      onTap: () => _openSetup(
                                        ConversationMode.together,
                                        null,
                                        true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const NoticeBanner(
                              message: AppStrings.sampleNotice,
                              icon: Icons.info_outline,
                              style: NoticeStyle.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            1 => ActivitiesScreen(
              repository: widget.activityRepository,
              discEnabled: features.discEnabled,
            ),
            2 => FavoritesScreen(
              storage: _favoritesStorage,
              repository: _questionRepository,
            ),
            _ => SupportScreen(
              licenseRepository: widget.licenseRepository,
              activationService: widget.activationService,
              questionUpdates: widget.questionUpdates,
              sessionStorage: _sessionStorage,
              appConfig: _appConfig,
              feedbackStorage: widget.feedbackStorage,
              onManageActivation: _openActivationManagement,
              onSyncContent: () async {
                if (widget.onSyncContent != null) {
                  await widget.onSyncContent!();
                }
                await _loadAppConfig();
                await _refreshQuestionCounts();
              },
            ),
          },
        ),
      ),
    );
  }
}

class _SavedSessionCard extends StatelessWidget {
  const _SavedSessionCard({
    required this.savedSession,
    required this.onResume,
    required this.onDiscard,
  });

  final SavedSessionState savedSession;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = savedSession.questionIds.length;
    final current = savedSession.currentIndex + 1;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return WefaqCard(
      hasShadow: true,
      backgroundColor: AppColors.surfaceWarm,
      borderColor: const Color(0xFFE4CFA8),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.iconContainerGold,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  color: AppColors.goldText,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text(
                  AppStrings.resumeCardTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  savedSession.mode.label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.questionProgress(current, total),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEADBC0),
              color: AppColors.goldText,
              semanticsLabel: AppStrings.resumeCardTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(AppStrings.resumeSessionButton),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.minTouchTarget),
                    textStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: onDiscard,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.minTouchTarget),
                  side: const BorderSide(color: AppColors.inputBorder),
                  textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text(AppStrings.discardSessionButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LicenseBarCard extends StatelessWidget {
  const _LicenseBarCard({
    required this.activationState,
    required this.onManage,
  });

  final ActivationState? activationState;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = activationState?.remaining;
    final license = activationState?.license;
    final isTrialActive = activationState?.isTrialActive(now) ?? false;
    final trialDays = isTrialActive
        ? (activationState?.trialRemainingDays(now) ?? 1)
        : 0;
    final isActive = license != null || isTrialActive;
    final statusText = license != null
        ? (remaining == null
              ? 'اشتراك مفعل (غير محدود)'
              : 'المتبقي: $remaining جلسة')
        : isTrialActive
        ? AppStrings.trialBarStatus(trialDays)
        : (activationState?.trialStartedAt != null
              ? 'انتهت التجربة المجانية'
              : 'بانتظار التفعيل');

    return WefaqCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      backgroundColor: AppColors.surfaceTinted,
      borderColor: AppColors.chipBorder,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: license != null
                  ? AppColors.iconContainerGreen
                  : AppColors.iconContainerGold,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              license != null
                  ? Icons.verified_outlined
                  : isActive
                  ? Icons.timer_outlined
                  : Icons.key_rounded,
              color: license != null ? AppColors.green : AppColors.goldText,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ),
          TextButton(
            onPressed: onManage,
            child: Text(license == null ? 'تفعيل الآن' : 'إدارة التفعيل'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.dark, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

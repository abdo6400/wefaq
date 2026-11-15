import 'dart:math';

import 'package:flutter/material.dart';

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
import '../licensing/licensing_data.dart';
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
  });

  final SessionStorage? sessionStorage;
  final QuestionRepository? questionRepository;
  final FavoritesStorage? favoritesStorage;
  final QuestionHistoryStorage? historyStorage;
  final LicenseRepository? licenseRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

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
  }

  Future<void> _openSetup([
    ConversationMode mode = ConversationMode.together,
    Topic? topic,
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
          initialTopic: topic ?? Topic.communication,
          repository: _questionRepository,
          storage: _sessionStorage,
          favoritesStorage: _favoritesStorage,
          historyStorage: _historyStorage,
        ),
      ),
    );
    _checkSavedSession();
  }

  Future<void> _showQuickSpark() async {
    final all = <Question>[];
    for (final depth in Depth.values) {
      all.addAll(await _questionRepository.getQuestions(depth: depth));
    }
    if (!mounted || all.isEmpty) return;

    final random = Random();
    var current = all[random.nextInt(all.length)];
    var isFav = await _favoritesStorage.isFavorite(current.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
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
                        current.topic.label,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                QuestionDialogueCard(
                  questionText: current.text,
                  clarificationText: current.clarification,
                  isFavorite: isFav,
                  onFavoriteToggle: () async {
                    final updated = await _favoritesStorage.toggleFavorite(
                      current.id,
                    );
                    setModalState(() => isFav = updated);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    final next = all[random.nextInt(all.length)];
                    final nextFav = await _favoritesStorage.isFavorite(next.id);
                    setModalState(() {
                      current = next;
                      isFav = nextFav;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('سؤال عشوائي آخر'),
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
    final horizontalPadding = screenWidth < 360
        ? AppSpacing.lg
        : AppSpacing.xxl;

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
          onDestinationSelected: (index) =>
              setState(() => _selectedTab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: AppStrings.navPlay,
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border_rounded),
              selectedIcon: Icon(Icons.star),
              label: AppStrings.navFavorites,
            ),
            NavigationDestination(
              icon: Icon(Icons.help_outline),
              selectedIcon: Icon(Icons.help),
              label: AppStrings.navHelp,
            ),
          ],
        ),
      ),
      body: switch (_selectedTab) {
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
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd + 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Image.asset(
                              'assets/images/wefaq_icon_concept.png',
                              width: 36,
                              height: 36,
                              semanticLabel: AppStrings.appLogoSemantics,
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
                    badgeText: AppStrings.prototypeBadge,
                    tagline: AppStrings.heroSubtitle,
                    title: AppStrings.welcomeTitle,
                    subtitle: AppStrings.heroDescription,
                    bottomOverlap: 24,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -24),
                          child: WefaqCard(
                            hasShadow: true,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 340;
                                final primaryBtn = FilledButton.icon(
                                  onPressed: _openSetup,
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    AppStrings.startPrototypeSession,
                                  ),
                                );
                                final sparkBtn = OutlinedButton.icon(
                                  onPressed: _showQuickSpark,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.iconContainerGold,
                                    foregroundColor: AppColors.dark,
                                    side: const BorderSide(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 19,
                                    color: AppColors.gold,
                                  ),
                                  label: const Text('سؤال سريع'),
                                );
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
                        if (_savedSession != null) ...[
                          WefaqCard(
                            hasShadow: true,
                            backgroundColor: const Color(0xFFFBF8F0),
                            borderColor: AppColors.gold,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.iconContainerGold,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.history_toggle_off,
                                        color: AppColors.gold,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm + 2),
                                    Expanded(
                                      child: Text(
                                        AppStrings.resumeCardTitle,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
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
                                        color: AppColors.tagBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusPill,
                                        ),
                                      ),
                                      child: Text(
                                        _savedSession!.mode.label,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          color: AppColors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  AppStrings.questionProgress(
                                    _savedSession!.currentIndex + 1,
                                    _savedSession!.questionIds.length,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: _resumeSession,
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          AppStrings.resumeSessionButton,
                                        ),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 44),
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
                                      onPressed: _discardSavedSession,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 44),
                                        side: const BorderSide(
                                          color: AppColors.chipBorder,
                                        ),
                                        textStyle: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        AppStrings.discardSessionButton,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _SectionHeader(
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
                                  icon: Icons.people_outline,
                                  title: AppStrings.modeTogetherTitle,
                                  subtitle: AppStrings.modeTogetherSubtitle,
                                  onTap: () =>
                                      _openSetup(ConversationMode.together),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ModeGridTile(
                                  icon: Icons.phone_outlined,
                                  title: AppStrings.modePhoneTitle,
                                  subtitle: AppStrings.modePhoneSubtitle,
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
                                  countBadge: '120 سؤال',
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
                                  countBadge: '120 سؤال',
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
                                  countBadge: '120 سؤال',
                                  onTap: () => _openSetup(
                                    ConversationMode.together,
                                    Topic.familyRelations,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TopicBentoTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: Topic.finances.label,
                                  countBadge: '120 سؤال',
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
                        TopicBentoTile(
                          icon: Icons.auto_awesome_outlined,
                          title: Topic.coreValues.label,
                          countBadge: '120 سؤال',
                          isGoldAccent: true,
                          onTap: () => _openSetup(
                            ConversationMode.together,
                            Topic.coreValues,
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
        1 => const ActivitiesScreen(),
        2 => FavoritesScreen(
          storage: _favoritesStorage,
          repository: _questionRepository,
        ),
        _ => const SupportScreen(),
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

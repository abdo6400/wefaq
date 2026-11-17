import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/wefaq_card.dart';
import '../../../core/widgets/wefaq_page_header.dart';
import '../../../core/widgets/wefaq_shimmer.dart';
import '../../disc/disc_screen.dart';
import '../../sessions/domain/models/question.dart';
import '../activity_data.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key, this.repository, this.discEnabled = true});

  final ActivityRepository? repository;
  final bool discEnabled;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late final ActivityRepository _repo =
      widget.repository ?? InMemoryActivityRepository();
  int? _scenarioCount;
  int? _priorityCount;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final scenarios = await _repo.getActivities(type: ActivityType.scenario);
      final priorities = await _repo.getActivities(
        type: ActivityType.priorityOrdering,
      );
      if (mounted) {
        setState(() {
          _scenarioCount = scenarios.length;
          _priorityCount = priorities.length;
        });
      }
    } catch (_) {
      // Keep counts null gracefully if unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
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
                badgeText: 'أنشطة وتفاعلات',
                title: AppStrings.playTitle,
                subtitle: AppStrings.playSubtitle,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= 460 && textScale <= 1.2;
                        final scenariosTile = _GameTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: AppStrings.playScenarios,
                          subtitle: AppStrings.playScenariosHint,
                          countBadge: _scenarioCount != null
                              ? '$_scenarioCount مواقف'
                              : null,
                          accentColor: AppColors.green,
                          accentBackground: AppColors.iconContainerGreen,
                          compact: isWide,
                          onTap: () => _open(context, ActivityType.scenario),
                        );
                        final prioritiesTile = _GameTile(
                          icon: Icons.format_list_numbered_rounded,
                          title: AppStrings.playPriorities,
                          subtitle: AppStrings.playPrioritiesHint,
                          countBadge: _priorityCount != null
                              ? '$_priorityCount تمارين'
                              : null,
                          accentColor: AppColors.topicBronze,
                          accentBackground: AppColors.iconContainerGold,
                          compact: isWide,
                          onTap: () =>
                              _open(context, ActivityType.priorityOrdering),
                        );
                        if (isWide) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: scenariosTile),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: prioritiesTile),
                              ],
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            scenariosTile,
                            const SizedBox(height: AppSpacing.md),
                            prioritiesTile,
                          ],
                        );
                      },
                    ),
                    if (widget.discEnabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      _FeaturedDiscTile(
                        title: AppStrings.discTitle,
                        subtitle: AppStrings.discHint,
                        badgeText: '8 أسئلة تأملية',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DiscScreen(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const NoticeBanner(
                      message: AppStrings.playReviewNotice,
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
    );
  }

  void _open(BuildContext context, ActivityType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivityPlayScreen(type: type, repository: _repo),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.accentBackground,
    required this.onTap,
    this.countBadge,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? countBadge;
  final Color accentColor;
  final Color accentBackground;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WefaqCard(
      hasShadow: true,
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTinted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accentColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style:
                (compact
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                    ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          if (countBadge != null || !compact) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: accentBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                countBadge ?? AppStrings.playStart,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedDiscTile extends StatelessWidget {
  const _FeaturedDiscTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.dark, AppColors.green, AppColors.greenLight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 2),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowDeep,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard + 2),
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                top: -28,
                end: -22,
                child: IgnorePointer(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.iconContainerGold,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.insights_outlined,
                            color: AppColors.goldText,
                            size: 24,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.dark.withValues(alpha: 0.44),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.surfaceWhite,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.surfaceWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dark.withValues(alpha: 0.44),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        border: Border.all(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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

class ActivityPlayScreen extends StatefulWidget {
  const ActivityPlayScreen({
    super.key,
    required this.type,
    required this.repository,
  });

  final ActivityType type;
  final ActivityRepository repository;

  @override
  State<ActivityPlayScreen> createState() => _ActivityPlayScreenState();
}

class _ActivityPlayScreenState extends State<ActivityPlayScreen> {
  List<Activity> _cards = [];
  final List<int> _ordered = [];
  int _index = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items = await widget.repository.getActivities(type: widget.type);
      if (!mounted) return;
      setState(() {
        _cards = List.of(items)..shuffle();
        _index = 0;
        _ordered.clear();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _next() => setState(() {
    _index++;
    _ordered.clear();
  });

  void _previous() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _ordered.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == ActivityType.scenario
        ? AppStrings.playScenarios
        : AppStrings.playPriorities;
    final hasCards = !_loading && !_failed && _cards.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: !hasCards
          ? null
          : Container(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          if (_index > 0) ...[
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: _previous,
                                child: const Text(AppStrings.previousCard),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            flex: 3,
                            child: _index + 1 < _cards.length
                                ? FilledButton.icon(
                                    onPressed: _next,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                    label: const Text(AppStrings.playNext),
                                  )
                                : FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('العودة للألعاب'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: SafeArea(
        bottom: !hasCards,
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: _loading
              ? Semantics(
                  label: 'جارٍ تحميل البطاقات',
                  child: const WefaqCardListShimmer(itemCount: 3),
                )
              : _failed
              ? Center(
                  child: TextButton(
                    onPressed: _load,
                    child: const Text(AppStrings.playRetry),
                  ),
                )
              : _cards.isEmpty
              ? const Center(child: Text(AppStrings.playNoCards))
              : _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final activity = _cards[_index];
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;
    final progressValue = (_index + 1) / _cards.length;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.lg,
      ),
      children: [
        WefaqCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
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
                    AppStrings.playProgress(_index + 1, _cards.length),
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      activity.topic.label,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progressValue),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: AppColors.progressTrack,
                    color: AppColors.green,
                    semanticsLabel: AppStrings.playProgress(
                      _index + 1,
                      _cards.length,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: WefaqCard(
            key: ValueKey(activity.id),
            hasShadow: true,
            borderRadius: AppSpacing.radiusHero + 2,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.iconContainerGold,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: Icon(
                        widget.type == ActivityType.scenario
                            ? Icons.chat_bubble_outline_rounded
                            : Icons.format_list_numbered_rounded,
                        color: AppColors.goldText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    activity.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  activity.situation,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (activity.options.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.playOrderHint,
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_ordered.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  liveRegion: true,
                  label:
                      'تم ترتيب ${_ordered.length} من ${activity.options.length}',
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iconContainerGold,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${_ordered.length} / ${activity.options.length}',
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < activity.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                button: true,
                selected: _ordered.contains(i),
                label: _ordered.contains(i)
                    ? 'المرتبة ${_ordered.indexOf(i) + 1}: ${activity.options[i]}'
                    : 'غير محدد: ${activity.options[i]}',
                hint: _ordered.contains(i)
                    ? 'اضغط لإلغاء الترتيب'
                    : 'اضغط لتحديد الترتيب',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _ordered.contains(i)
                        ? AppColors.tagBackground
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: _ordered.contains(i)
                          ? AppColors.green
                          : AppColors.inputBorder,
                      width: _ordered.contains(i) ? 1.5 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      onTap: () => setState(() {
                        if (_ordered.contains(i)) {
                          _ordered.remove(i);
                        } else {
                          _ordered.add(i);
                        }
                      }),
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md + 2),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _ordered.contains(i)
                                      ? AppColors.green
                                      : AppColors.surfaceTinted,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _ordered.contains(i)
                                      ? '${_ordered.indexOf(i) + 1}'
                                      : '–',
                                  style: TextStyle(
                                    color: _ordered.contains(i)
                                        ? AppColors.surfaceWhite
                                        : AppColors.dark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  activity.options[i],
                                  style: TextStyle(
                                    fontWeight: _ordered.contains(i)
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: AppColors.dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              const Text(
                AppStrings.playChoiceNote,
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              TextButton.icon(
                onPressed: _ordered.isEmpty
                    ? null
                    : () => setState(_ordered.clear),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text(AppStrings.playReset),
              ),
            ],
          ),
        ],
        if (activity.prompts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              AppStrings.playPrompts,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.dark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final prompt in activity.prompts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.iconContainerGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.question_answer_outlined,
                          size: 13,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: AppColors.dark,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        const NoticeBanner(
          message: AppStrings.playReviewNotice,
          icon: Icons.info_outline,
          style: NoticeStyle.warning,
        ),
      ],
    );
  }
}

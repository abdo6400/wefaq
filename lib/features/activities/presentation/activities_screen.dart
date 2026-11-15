import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/wefaq_page_header.dart';
import '../activity_data.dart';
import '../../disc/disc_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key, this.repository});
  final ActivityRepository? repository;

  @override
  Widget build(BuildContext context) {
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
                badgeText: 'أنشطة وتفاعلات',
                title: AppStrings.playTitle,
                subtitle: AppStrings.playSubtitle,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 330;
                        final scenariosTile = _GameTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: AppStrings.playScenarios,
                          subtitle: AppStrings.playScenariosHint,
                          color: AppColors.green,
                          compact: isWide,
                          onTap: () => _open(context, ActivityType.scenario),
                        );
                        final prioritiesTile = _GameTile(
                          icon: Icons.format_list_numbered_rounded,
                          title: AppStrings.playPriorities,
                          subtitle: AppStrings.playPrioritiesHint,
                          color: AppColors.dark,
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
                    const SizedBox(height: AppSpacing.md),
                    _GameTile(
                      icon: Icons.insights_outlined,
                      title: AppStrings.discTitle,
                      subtitle: AppStrings.discHint,
                      color: AppColors.green,
                      isGoldHighlight: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DiscScreen(),
                        ),
                      ),
                    ),
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
        builder: (_) => ActivityPlayScreen(
          type: type,
          repository: repository ?? InMemoryActivityRepository(),
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
    this.isGoldHighlight = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;
  final bool isGoldHighlight;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: isGoldHighlight
          ? const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [AppColors.dark, AppColors.green],
            )
          : null,
      color: isGoldHighlight ? null : color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      border: isGoldHighlight
          ? Border.all(color: AppColors.gold, width: 1.5)
          : null,
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: isGoldHighlight
                          ? AppColors.iconContainerGold
                          : AppColors.surfaceWhite.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: isGoldHighlight
                          ? AppColors.gold
                          : AppColors.surfaceWhite,
                      size: compact ? 22 : 26,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.16),
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
                style:
                    (compact
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.titleLarge)
                        ?.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.bold,
                        ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.background, height: 1.45),
              ),
              if (!compact) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: const Text(
                    AppStrings.playStart,
                    style: TextStyle(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
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
  @override
  Widget build(BuildContext context) {
    final title = widget.type == ActivityType.scenario
        ? AppStrings.playScenarios
        : AppStrings.playPriorities;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ResponsiveContainer(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        Text(
          AppStrings.playProgress(_index + 1, _cards.length),
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: (_index + 1) / _cards.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.iconContainerGold,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    widget.type == ActivityType.scenario
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.format_list_numbered_rounded,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                activity.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
        if (activity.options.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text(AppStrings.playOrderHint),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < activity.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () => setState(() {
                    if (_ordered.contains(i)) {
                      _ordered.remove(i);
                    } else {
                      _ordered.add(i);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _ordered.contains(i)
                              ? AppColors.green
                              : AppColors.tagBackground,
                          foregroundColor: _ordered.contains(i)
                              ? AppColors.surfaceWhite
                              : AppColors.dark,
                          child: Text(
                            _ordered.contains(i)
                                ? '${_ordered.indexOf(i) + 1}'
                                : '–',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(activity.options[i])),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Text(
            AppStrings.playChoiceNote,
            style: TextStyle(color: AppColors.muted),
          ),
          TextButton(
            onPressed: _ordered.isEmpty ? null : () => setState(_ordered.clear),
            child: const Text(AppStrings.playReset),
          ),
        ],
        if (activity.prompts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.playPrompts,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final prompt in activity.prompts)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text('• $prompt'),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const NoticeBanner(
          message: AppStrings.playReviewNotice,
          icon: Icons.info_outline,
          style: NoticeStyle.warning,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_index + 1 < _cards.length)
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text(AppStrings.playNext),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('العودة للألعاب'),
          ),
      ],
    );
  }
}

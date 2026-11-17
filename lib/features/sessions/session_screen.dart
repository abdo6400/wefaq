import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/wefaq_card.dart';
import '../favorites/domain/repositories/favorites_storage.dart';
import '../feedback/presentation/widgets/feedback_sheet.dart';
import 'domain/models/question.dart';
import 'domain/models/saved_session_state.dart';
import 'domain/models/session_progress.dart';
import 'domain/repositories/session_storage.dart';
import 'presentation/widgets/question_dialogue_card.dart';
import 'presentation/widgets/session_progress_header.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.questions,
    required this.mode,
    this.questionIds,
    this.clarifications,
    this.topicLabels,
    this.depthLabels,
    this.initialIndex = 0,
    this.initialSkipped = const {},
    this.storage,
    this.favoritesStorage,
    this.sessionId,
  });

  /// Factory constructor to initialize from strongly-typed [Question] models.
  factory SessionScreen.fromQuestions({
    Key? key,
    required List<Question> items,
    required ConversationMode mode,
    int initialIndex = 0,
    Set<int> initialSkipped = const {},
    SessionStorage? storage,
    FavoritesStorage? favoritesStorage,
    String? sessionId,
  }) {
    return SessionScreen(
      key: key,
      questions: items.map((q) => q.text).toList(),
      questionIds: items.map((q) => q.id).toList(),
      clarifications: items.map((q) => q.clarification).toList(),
      topicLabels: items.map((q) => q.topic.label).toList(),
      depthLabels: items.map((q) => q.depth.label).toList(),
      mode: mode,
      initialIndex: initialIndex,
      initialSkipped: initialSkipped,
      storage: storage,
      favoritesStorage: favoritesStorage,
      sessionId: sessionId,
    );
  }

  final List<String> questions;
  final ConversationMode mode;
  final List<String>? questionIds;
  final List<String?>? clarifications;
  final List<String>? topicLabels;
  final List<String>? depthLabels;
  final int initialIndex;
  final Set<int> initialSkipped;
  final SessionStorage? storage;
  final FavoritesStorage? favoritesStorage;
  final String? sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionProgress<String> progress = SessionProgress<String>(
    widget.questions,
    initialIndex: widget.initialIndex,
    initialSkipped: widget.initialSkipped,
  );
  late final String _sessionId =
      widget.sessionId ?? 'session-${DateTime.now().millisecondsSinceEpoch}';

  bool _isCurrentFavorite = false;
  bool _favoriteBusy = false;
  Future<void> _storageQueue = Future.value();

  Future<void> _enqueueStorage(Future<void> Function() action) {
    _storageQueue = _storageQueue.then((_) => action()).catchError((Object _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ البيانات على الجهاز. حاول مرة أخرى.'),
          ),
        );
      }
    });
    return _storageQueue;
  }

  @override
  void initState() {
    super.initState();
    _persistState();
    _checkFavorite();
  }

  String get _currentQuestionId {
    final ids = widget.questionIds ?? widget.questions;
    if (progress.index < ids.length) {
      return ids[progress.index];
    }
    return '';
  }

  Future<void> _checkFavorite() async {
    final fs = widget.favoritesStorage;
    if (fs == null) return;
    final questionId = _currentQuestionId;
    try {
      final isFav = await fs.isFavorite(questionId);
      if (mounted && questionId == _currentQuestionId) {
        setState(() => _isCurrentFavorite = isFav);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر قراءة المفضلة على الجهاز.')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final fs = widget.favoritesStorage;
    if (fs == null || _favoriteBusy) return;
    final questionId = _currentQuestionId;
    _favoriteBusy = true;
    try {
      final added = await fs.toggleFavorite(questionId);
      if (mounted && questionId == _currentQuestionId) {
        setState(() => _isCurrentFavorite = added);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ المفضلة على الجهاز.')),
        );
      }
    } finally {
      _favoriteBusy = false;
    }
  }

  Future<void> _copyCurrentQuestion() async {
    final text = progress.questions[progress.index];
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.questionCopiedMessage),
            backgroundColor: AppColors.green,
          ),
        );
    }
  }

  Future<void> _persistState() async {
    final s = widget.storage;
    if (s == null || progress.complete) return;
    final ids = widget.questionIds ?? widget.questions;
    final state = SavedSessionState(
      sessionId: _sessionId,
      questionIds: ids,
      mode: widget.mode,
      currentIndex: progress.index,
      skippedIndices: progress.skippedIndices,
      updatedAt: DateTime.now().toUtc(),
    );
    await _enqueueStorage(() => s.writeActiveSession(state));
  }

  Future<void> _clearState() async {
    final s = widget.storage;
    if (s != null) {
      await _enqueueStorage(s.clearActiveSession);
    }
  }

  Future<void> exit() async {
    if (progress.complete) {
      await _clearState();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.exitDialogTitle),
        content: const Text(AppStrings.exitDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.continueSessionAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.exitSessionAction),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      await _clearState();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onAdvance({required bool skipped}) {
    setState(() => progress.advance(skipped: skipped));
    if (progress.complete) {
      _clearState();
    } else {
      _persistState();
      _checkFavorite();
    }
  }

  void _onPrevious() {
    setState(progress.previous);
    _persistState();
    _checkFavorite();
  }

  void _reviewSkippedQuestions() {
    final skippedIndices = progress.skippedIndices.toList()..sort();
    if (skippedIndices.isEmpty) return;

    final skippedQuestions = [
      for (final idx in skippedIndices) widget.questions[idx],
    ];
    final skippedIds = widget.questionIds == null
        ? null
        : [for (final idx in skippedIndices) widget.questionIds![idx]];
    final skippedClarifications = widget.clarifications == null
        ? null
        : [for (final idx in skippedIndices) widget.clarifications![idx]];
    final skippedTopics = widget.topicLabels == null
        ? null
        : [for (final idx in skippedIndices) widget.topicLabels![idx]];
    final skippedDepths = widget.depthLabels == null
        ? null
        : [for (final idx in skippedIndices) widget.depthLabels![idx]];

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(
          questions: skippedQuestions,
          questionIds: skippedIds,
          clarifications: skippedClarifications,
          topicLabels: skippedTopics,
          depthLabels: skippedDepths,
          mode: widget.mode,
          favoritesStorage: widget.favoritesStorage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return PopScope(
      canPop: progress.complete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            progress.complete
                ? AppStrings.sessionFinishedTitle
                : '${AppStrings.sessionModePrefix} ${widget.mode.label}',
          ),
        ),
        bottomNavigationBar: progress.complete
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
                            FilledButton.icon(
                              onPressed: () => _onAdvance(skipped: false),
                              icon: Icon(
                                progress.isLastQuestion
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(
                                progress.isLastQuestion
                                    ? AppStrings.finishSessionButton
                                    : AppStrings.nextButton,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: !progress.hasPrevious
                                        ? null
                                        : _onPrevious,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        AppSpacing.minTouchTarget,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 17,
                                    ),
                                    label: const Text(
                                      AppStrings.previousButton,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _onAdvance(skipped: true),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        AppSpacing.minTouchTarget,
                                      ),
                                    ),
                                    icon: Transform.scale(
                                      scaleX: isRtl ? -1 : 1,
                                      child: const Icon(
                                        Icons.fast_forward_rounded,
                                        size: 17,
                                      ),
                                    ),
                                    label: const Text(AppStrings.skipButton),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        body: SafeArea(
          bottom: progress.complete,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                children: progress.complete
                    ? [
                        WefaqCard(
                          hasShadow: true,
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExcludeSemantics(
                                child: Center(
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconContainerGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.tagBackground,
                                        width: 4,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.green,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Text(
                                  'بارك الله في حواركم الهادئ',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'نرجو أن تكون هذه الجلسة قد قرّبت الفهم بينكما.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceTinted,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.discussedQuestions(
                                    progress.discussedCount,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFEBDAC0),
                                  ),
                                ),
                                child: Text(
                                  AppStrings.skippedQuestions(
                                    progress.skippedCount,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              if (progress.skippedCount > 0) ...[
                                OutlinedButton.icon(
                                  onPressed: _reviewSkippedQuestions,
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    AppStrings.reviewSkippedQuestions,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              FilledButton(
                                onPressed: exit,
                                child: const Text(AppStrings.returnToSetup),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => FeedbackSheet.show(context),
                                icon: const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'شاركنا رأيك في تجربة الجلسة',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    : [
                        SessionProgressHeader(
                          modeLabel: widget.mode.label,
                          currentIndex: progress.index,
                          totalQuestions: progress.questions.length,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Semantics(
                          liveRegion: true,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.03),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: QuestionDialogueCard(
                              key: ValueKey(progress.index),
                              questionText: progress.questions[progress.index],
                              clarificationText:
                                  widget.clarifications != null &&
                                      progress.index <
                                          widget.clarifications!.length
                                  ? widget.clarifications![progress.index]
                                  : null,
                              topicLabel:
                                  widget.topicLabels != null &&
                                      progress.index <
                                          widget.topicLabels!.length
                                  ? widget.topicLabels![progress.index]
                                  : null,
                              depthLabel:
                                  widget.depthLabels != null &&
                                      progress.index <
                                          widget.depthLabels!.length
                                  ? widget.depthLabels![progress.index]
                                  : null,
                              isFavorite: _isCurrentFavorite,
                              onFavoriteToggle: widget.favoritesStorage != null
                                  ? _toggleFavorite
                                  : null,
                              onCopyQuestion: _copyCurrentQuestion,
                              onReportQuestion: () {
                                final currentQId =
                                    widget.questionIds != null &&
                                        progress.index <
                                            widget.questionIds!.length
                                    ? widget.questionIds![progress.index]
                                    : null;
                                FeedbackSheet.show(
                                  context,
                                  questionId: currentQId,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const NoticeBanner(
                          message: AppStrings.sessionPacingNotice,
                          icon: Icons.spa_outlined,
                          style: NoticeStyle.info,
                        ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

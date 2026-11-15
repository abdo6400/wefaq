import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) => PopScope(
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final horizontalPadding = screenWidth < 360
                    ? AppSpacing.lg
                    : AppSpacing.xxl;

                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.xl,
                  ),
                  children: progress.complete
                      ? [
                          WefaqCard(
                            hasShadow: true,
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: AppColors.iconContainerGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.green,
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  AppStrings.discussedQuestions(
                                    progress.discussedCount,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.dark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.noticeBackground,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      AppStrings.skippedQuestions(
                                        progress.skippedCount,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.dark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
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
                          const SizedBox(height: AppSpacing.xxxl),
                          QuestionDialogueCard(
                            questionText: progress.questions[progress.index],
                            clarificationText:
                                widget.clarifications != null &&
                                    progress.index <
                                        widget.clarifications!.length
                                ? widget.clarifications![progress.index]
                                : null,
                            isFavorite: _isCurrentFavorite,
                            onFavoriteToggle: widget.favoritesStorage != null
                                ? _toggleFavorite
                                : null,
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
                          const SizedBox(height: AppSpacing.lg + 2),
                          const NoticeBanner(
                            message: AppStrings.sessionPacingNotice,
                            icon: Icons.spa_outlined,
                            style: NoticeStyle.info,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _onAdvance(skipped: false),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                progress.isLastQuestion
                                    ? AppStrings.finishSessionButton
                                    : AppStrings.nextButton,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm + 2),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: !progress.hasPrevious
                                      ? null
                                      : _onPrevious,
                                  child: const Text(AppStrings.previousButton),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _onAdvance(skipped: true),
                                  child: const Text(AppStrings.skipButton),
                                ),
                              ),
                            ],
                          ),
                        ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

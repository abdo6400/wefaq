import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/wefaq_card.dart';
import '../../../core/widgets/wefaq_page_header.dart';
import '../../sessions/data/in_memory_question_repository.dart';
import '../../sessions/domain/models/question.dart';
import '../../sessions/domain/repositories/question_repository.dart';
import '../domain/models/favorite_question_item.dart';
import '../domain/repositories/favorites_storage.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.storage, this.repository});

  final FavoritesStorage storage;
  final QuestionRepository? repository;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final QuestionRepository _repository =
      widget.repository ?? InMemoryQuestionRepository();

  List<FavoriteQuestionItem> _favorites = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  Map<String, Question> _questionsById = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final list = await widget.storage.getFavorites();
      final questions = <Question>[];
      for (final depth in Depth.values) {
        questions.addAll(await _repository.getQuestions(depth: depth));
      }
      if (mounted) {
        setState(() {
          _favorites = list;
          _questionsById = {
            for (final question in questions) question.id: question,
          };
          _isLoading = false;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _removeFavorite(String questionId) async {
    try {
      await widget.storage.removeFavorite(questionId);
      await _loadFavorites();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر تعديل المفضلة.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
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
                  badgeText: '${_favorites.length} محفوظ',
                  title: AppStrings.favoritesTitle,
                  subtitle:
                      'أسئلة تحفظها محليًا على هذا الجهاز للمراجعة الهادئة',
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _loadFailed
                      ? Center(
                          child: TextButton(
                            onPressed: _loadFavorites,
                            child: const Text(
                              'تعذر تحميل المفضلة. حاول مرة أخرى.',
                            ),
                          ),
                        )
                      : _favorites.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          children: [
                            WefaqCard(
                              hasShadow: true,
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconContainerGold,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.gold,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star_border_rounded,
                                      color: AppColors.gold,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  Text(
                                    AppStrings.emptyFavoritesMessage,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          children: [
                            const NoticeBanner(
                              message: 'هذه الأسئلة محفوظة محليًا على هذا الجهاز فقط، لمراجعتها والتأمل فيها في أي وقت.',
                              icon: Icons.lock_outline,
                              style: NoticeStyle.info,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (final fav in _favorites) ...[
                              _FavoriteCard(
                                questionId: fav.questionId,
                                question: _questionsById[fav.questionId],
                                onRemove: () => _removeFavorite(fav.questionId),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
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

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.questionId,
    required this.question,
    required this.onRemove,
  });

  final String questionId;
  final Question? question;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = question?.text ?? questionId;
    final topicLabel = question?.topic.label ?? '';
    final clarification = question?.clarification;

    return WefaqCard(
      hasShadow: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (topicLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tagBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    topicLabel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.iconContainerGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold),
                ),
                child: IconButton(
                  onPressed: onRemove,
                  tooltip: AppStrings.removeFromFavoritesTooltip,
                  icon: const Icon(Icons.star, color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          if (clarification != null && clarification.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.tipBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                clarification,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

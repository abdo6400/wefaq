import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/wefaq_card.dart';
import '../../../core/widgets/wefaq_page_header.dart';
import '../../../core/widgets/wefaq_shimmer.dart';
import '../../sessions/data/in_memory_question_repository.dart';
import '../../sessions/domain/models/question.dart';
import '../../sessions/domain/repositories/question_repository.dart';
import '../../sessions/session_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();

  List<FavoriteQuestionItem> _favorites = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  Map<String, Question> _questionsById = {};
  Topic? _selectedTopic;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _copyQuestion(String text) async {
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

  List<FavoriteQuestionItem> get _filteredFavorites {
    return _favorites.where((fav) {
      final q = _questionsById[fav.questionId];
      if (_selectedTopic != null && q?.topic != _selectedTopic) return false;
      if (_search.isNotEmpty) {
        final hay = '${q?.text ?? fav.questionId}\n${q?.clarification ?? ''}'
            .toLowerCase();
        if (!hay.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _openAsCards(List<FavoriteQuestionItem> items) {
    final questions = [
      for (final fav in items)
        if (_questionsById[fav.questionId] != null)
          _questionsById[fav.questionId]!,
    ];
    if (questions.isEmpty) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => SessionScreen.fromQuestions(
              items: questions,
              mode: ConversationMode.together,
              favoritesStorage: widget.storage,
            ),
          ),
        )
        .then((_) => _loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final filtered = _filteredFavorites;
    final availableTopics = <Topic>{
      for (final fav in _favorites)
        if (_questionsById[fav.questionId] != null)
          _questionsById[fav.questionId]!.topic,
    };
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.lg : AppSpacing.xl;

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
                  badgeText: '${_favorites.length} محفوظ',
                  title: AppStrings.favoritesTitle,
                  subtitle:
                      'أسئلة تحفظها محليًا على هذا الجهاز للمراجعة الهادئة',
                ),
                Expanded(
                  child: _isLoading
                      ? Semantics(
                          label: 'جارٍ تحميل المفضلة',
                          child: const WefaqCardListShimmer(itemCount: 4),
                        )
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
                          padding: EdgeInsets.all(horizontalPadding),
                          children: [
                            WefaqCard(
                              hasShadow: true,
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ExcludeSemantics(
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.iconContainerGold,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE7D3AE),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.star_border_rounded,
                                        color: AppColors.goldText,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    'مفضلتكما هادئة حتى الآن',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: AppColors.dark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: AppSpacing.lg,
                          ),
                          children: [
                            const NoticeBanner(
                              message: 'هذه الأسئلة محفوظة محليًا على هذا الجهاز فقط، لمراجعتها والتأمل فيها في أي وقت.',
                              icon: Icons.lock_outline,
                              style: NoticeStyle.info,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_favorites.length >= 2 &&
                                filtered.any(
                                  (f) =>
                                      _questionsById.containsKey(f.questionId),
                                )) ...[
                              OutlinedButton.icon(
                                onPressed: () => _openAsCards(filtered),
                                icon: const Icon(
                                  Icons.style_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  AppStrings.reviewFavoritesAsCards,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (_favorites.length >= 3) ...[
                              TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _search = val.trim()),
                                decoration: InputDecoration(
                                  hintText: AppStrings.favoritesSearchHint,
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _search.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _search = '');
                                          },
                                          tooltip: 'مسح البحث',
                                          icon: const Icon(Icons.close_rounded),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppColors.surfaceWhite,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.inputBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.inputBorder,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm + 2),
                            ],
                            if (availableTopics.length > 1) ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('الكل'),
                                      selected: _selectedTopic == null,
                                      showCheckmark: false,
                                      selectedColor: AppColors.green,
                                      backgroundColor: AppColors.surfaceWhite,
                                      side: BorderSide(
                                        color: _selectedTopic == null
                                            ? AppColors.green
                                            : AppColors.inputBorder,
                                      ),
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedTopic == null
                                            ? AppColors.surfaceWhite
                                            : AppColors.dark,
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _selectedTopic = null),
                                    ),
                                    for (final topic in availableTopics) ...[
                                      const SizedBox(width: AppSpacing.xs + 2),
                                      ChoiceChip(
                                        label: Text(topic.label),
                                        selected: _selectedTopic == topic,
                                        showCheckmark: false,
                                        selectedColor: AppColors.green,
                                        backgroundColor: AppColors.surfaceWhite,
                                        side: BorderSide(
                                          color: _selectedTopic == topic
                                              ? AppColors.green
                                              : AppColors.inputBorder,
                                        ),
                                        labelStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedTopic == topic
                                              ? AppColors.surfaceWhite
                                              : AppColors.dark,
                                        ),
                                        onSelected: (_) => setState(
                                          () => _selectedTopic = topic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (filtered.isEmpty)
                              Semantics(
                                liveRegion: true,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xxl,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'لا توجد أسئلة محفوظة مطابقة للبحث.',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (final fav in filtered) ...[
                                _FavoriteCard(
                                  questionId: fav.questionId,
                                  question: _questionsById[fav.questionId],
                                  onRemove: () =>
                                      _removeFavorite(fav.questionId),
                                  onCopy: () => _copyQuestion(
                                    _questionsById[fav.questionId]?.text ??
                                        fav.questionId,
                                  ),
                                  onOpenCard:
                                      _questionsById.containsKey(fav.questionId)
                                      ? () => _openAsCards([fav])
                                      : null,
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
    required this.onCopy,
    this.onOpenCard,
  });

  final String questionId;
  final Question? question;
  final VoidCallback onRemove;
  final VoidCallback onCopy;
  final VoidCallback? onOpenCard;

  @override
  Widget build(BuildContext context) {
    final text = question?.text ?? questionId;
    final topicLabel = question?.topic.label ?? '';
    final depthLabel = question?.depth.label ?? '';
    final clarification = question?.clarification;

    return WefaqCard(
      hasShadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      onTap: onOpenCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (topicLabel.isNotEmpty)
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
                          topicLabel,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (depthLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          depthLabel,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onCopy,
                tooltip: AppStrings.copyQuestionTooltip,
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.muted,
                  size: 19,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.iconContainerGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldText),
                ),
                child: IconButton(
                  onPressed: onRemove,
                  tooltip: AppStrings.removeFromFavoritesTooltip,
                  icon: const Icon(Icons.star, color: AppColors.goldText),
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
              height: 1.55,
            ),
          ),
          if (clarification != null && clarification.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.tipBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                clarification,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

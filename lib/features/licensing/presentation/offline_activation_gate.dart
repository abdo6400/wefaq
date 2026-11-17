import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../core/widgets/wefaq_card.dart';
import '../../../core/widgets/wefaq_page_header.dart';
import '../domain/models/activation_link.dart';
import '../domain/repositories/offline_activation.dart';

class OfflineActivationGate extends StatefulWidget {
  const OfflineActivationGate({
    super.key,
    required this.service,
    required this.child,
    this.forceActivation = false,
    this.linkHost = '',
    this.links,
    this.contactConfig,
    this.clock,
  });

  final OfflineActivation service;
  final Widget child;
  final bool forceActivation;
  final String linkHost;
  final Stream<Uri>? links;
  final AppContactConfig? contactConfig;
  final DateTime Function()? clock;

  @override
  State<OfflineActivationGate> createState() => _OfflineActivationGateState();
}

class _OfflineActivationGateState extends State<OfflineActivationGate>
    with WidgetsBindingObserver {
  final _code = TextEditingController();
  ActivationState? _state;
  bool _busy = true;
  String? _error;
  Timer? _expiryTimer;
  StreamSubscription<Uri>? _linkSubscription;
  Future<void> _linkQueue = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.forceActivation && widget.links != null) {
      _linkSubscription = widget.links!.listen(
        (uri) {
          _linkQueue = _linkQueue
              .then((_) => _handleLink(uri))
              .catchError((Object _) {});
        },
        onError: (Object _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.activationLinkFailure)),
            );
          }
        },
      );
    }
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiryTimer?.cancel();
    _linkSubscription?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _handleLink(Uri uri) async {
    final code = activationCodeFromLink(uri, widget.linkHost);
    if (code == null) return;
    try {
      final current = await widget.service.state();
      final incoming = await widget.service.inspect(code);
      if (!mounted) return;
      if (current.license != null && current.license!.id != incoming.id) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(AppStrings.activationReplaceTitle),
            content: const Text(AppStrings.activationReplaceBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(AppStrings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(AppStrings.activationReplaceConfirm),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      await widget.service.activate(code);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.activationLinkSuccess)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.activationLinkFailure)),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  Future<void> _refresh() async {
    try {
      final state = await widget.service.state();
      if (!mounted) return;
      _expiryTimer?.cancel();
      final now = _now();
      final expiry = state.license != null
          ? state.license!.expiresAt
          : (state.isTrialActive(now) ? state.trialEndsAt : null);
      if (expiry != null) {
        final delay = expiry.difference(now.toUtc());
        if (delay > Duration.zero) {
          const maxStep = Duration(days: 7);
          _expiryTimer = Timer(delay > maxStep ? maxStep : delay, _refresh);
        }
      }
      if (!widget.forceActivation &&
          widget.service.isConfigured &&
          !state.hasAccess(now)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
          }
        });
      }
      if (mounted) {
        setState(() {
          _state = state;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.activationStorageError;
        });
      }
    }
  }

  Future<void> _activate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.activate(_code.text);
      _code.clear();
      if (widget.forceActivation && mounted) {
        Navigator.of(context).pop();
        return;
      }
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.activationCodeError;
        });
      }
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.activationClipboardEmpty)),
      );
      return;
    }
    setState(() {
      _code.text = text;
      _error = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.activationPasted)));
  }

  Future<void> _copyInstallationId(String installationId) async {
    await Clipboard.setData(ClipboardData(text: installationId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.installationCopied)),
      );
    }
  }

  void _showRequestCodeDialog(String installationId) {
    final contact = widget.contactConfig ?? const AppContactConfig();
    final message =
        '${contact.contactMessageTemplate}\nمعرّف التثبيت الخاص بجهازي:\n$installationId';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          AppStrings.activationRequestCode,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'انسخ الرسالة التالية وأرسلها لفريق الدعم للحصول على كود التفعيل الخاص بجهازك:',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(fontSize: 12.5, color: AppColors.dark),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'البريد: ${contact.email}\n${contact.supportHours}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancelAction),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ رسالة طلب التفعيل بنجاح.'),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('نسخ الرسالة'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final license = state?.license;
    final now = _now();
    if (!widget.forceActivation &&
        !_busy &&
        _error == null &&
        widget.service.isConfigured &&
        state != null &&
        state.hasAccess(now)) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final canPop = widget.forceActivation && Navigator.of(context).canPop();
    final isValidNow =
        state != null &&
        license != null &&
        license.permits(state.installationId, now) &&
        (state.remaining == null || state.remaining! > 0);
    final hasTrial =
        state != null && license == null && state.trialStartedAt != null;
    final isTrialActive = hasTrial && state.isTrialActive(now);
    final isTrialExpired = hasTrial && !isTrialActive;
    final trialDaysLeft = isTrialActive
        ? (state.trialRemainingDays(now) ?? 1)
        : 0;
    final screenWidth = MediaQuery.sizeOf(context).width;
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
                    : ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm + 2,
                            ),
                            child: Image.asset(
                              'assets/images/wefaq_icon_concept.png',
                              width: 30,
                              height: 30,
                              semanticLabel: AppStrings.appLogoSemantics,
                            ),
                          ),
                        ),
                      ),
                badgeText: isValidNow
                    ? 'مفعل'
                    : isTrialActive
                    ? AppStrings.activationTrialActiveBadge
                    : isTrialExpired
                    ? AppStrings.activationTrialExpiredBadge
                    : 'التفعيل',
                title: AppStrings.activationTitle,
                subtitle: isTrialExpired
                    ? AppStrings.activationTrialExpiredSubtitle
                    : AppStrings.activationInstructions,
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.service.isConfigured) ...[
                      const NoticeBanner(
                        message: AppStrings.activationUnconfigured,
                        icon: Icons.warning_amber_rounded,
                        style: NoticeStyle.warning,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const NoticeBanner(
                        message: AppStrings.activationUnconfiguredHint,
                        icon: Icons.vpn_key_outlined,
                        style: NoticeStyle.info,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (isTrialExpired && widget.service.isConfigured) ...[
                      NoticeBanner(
                        message: state.trialClockTampered
                            ? AppStrings.activationTrialClockTamperedNotice
                            : AppStrings.activationTrialExpiredNotice,
                        icon: Icons.lock_clock_outlined,
                        style: NoticeStyle.warning,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (isTrialActive && widget.service.isConfigured) ...[
                      WefaqCard(
                        hasShadow: true,
                        backgroundColor: AppColors.tagBackground,
                        borderColor: AppColors.green,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.green,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      AppStrings.activationTrialCardTitle,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                          ),
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
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                  ),
                                  child: const Text(
                                    AppStrings.activationTrialActiveBadge,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              AppStrings.trialRemainingDays(trialDaysLeft),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            if (state.trialEndsAt != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${AppStrings.activationExpiryDate}: ${_formatDate(state.trialEndsAt!)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              AppStrings.activationTrialAutoCloseHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (state != null && license != null) ...[
                      WefaqCard(
                        hasShadow: true,
                        backgroundColor: isValidNow
                            ? AppColors.tagBackground
                            : AppColors.surfaceWarm,
                        borderColor: isValidNow
                            ? AppColors.green
                            : AppColors.gold,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isValidNow
                                      ? Icons.verified_rounded
                                      : Icons.schedule_rounded,
                                  color: isValidNow
                                      ? AppColors.green
                                      : AppColors.goldText,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      AppStrings.activationCurrentLicense,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                          ),
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
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    isValidNow ? 'ساري' : 'يحتاج تجديد',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isValidNow
                                          ? AppColors.green
                                          : AppColors.goldText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              state.remaining == null
                                  ? AppStrings.activationUnlimited
                                  : AppStrings.activationRemaining(
                                      state.remaining!,
                                    ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${AppStrings.activationExpiryDate}: ${license.expiresAt != null ? _formatDate(license.expiresAt!) : AppStrings.activationNoExpiry}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              '${AppStrings.activationLicenseId}: ${license.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    WefaqCard(
                      hasShadow: true,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconContainerGold,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.vpn_key_outlined,
                                      color: AppColors.goldText,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm + 2),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      AppStrings.activationCode,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _busy || !widget.service.isConfigured
                                    ? null
                                    : _pasteCode,
                                icon: const Icon(
                                  Icons.content_paste_rounded,
                                  size: 17,
                                ),
                                label: const Text(
                                  AppStrings.activationPasteCode,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _code,
                            enabled: !_busy && widget.service.isConfigured,
                            autocorrect: false,
                            enableSuggestions: false,
                            enableIMEPersonalizedLearning: false,
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              hintText: 'eyJ2IjoxLC...signature',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            NoticeBanner(
                              message: _error!,
                              icon: Icons.error_outline,
                              style: NoticeStyle.warning,
                              isLiveRegion: true,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: _busy || !widget.service.isConfigured
                                ? null
                                : _activate,
                            child: Text(
                              _busy
                                  ? AppStrings.activating
                                  : AppStrings.activate,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              onPressed: _busy ? null : _refresh,
                              child: const Text(AppStrings.retry),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      WefaqCard(
                        hasShadow: true,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.iconContainerGreen,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.smartphone_outlined,
                                    color: AppColors.green,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      AppStrings.installationIdLabel,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.dark,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: SelectableText(
                                state.installationId,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _copyInstallationId(state.installationId),
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text(
                                    AppStrings.copyInstallation,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showRequestCodeDialog(
                                    state.installationId,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      0,
                                      AppSpacing.minTouchTarget,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    AppStrings.activationRequestCode,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

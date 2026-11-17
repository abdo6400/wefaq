import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'core/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/config/app_env.dart';
import 'features/activities/activity_data.dart';
import 'features/activities/data/cached_activity_repository.dart';
import 'features/favorites/data/favorites_storage.dart';
import 'features/favorites/domain/repositories/favorites_storage.dart';
import 'features/feedback/feedback_data.dart';
import 'features/home/home_screen.dart';
import 'features/licensing/data/offline_activation_service.dart';
import 'features/licensing/domain/repositories/offline_activation.dart';
import 'features/licensing/licensing_data.dart';
import 'features/licensing/presentation/offline_activation_gate.dart';
import 'features/sessions/data/cached_question_repository.dart';
import 'features/sessions/domain/repositories/question_updates.dart';
import 'features/sessions/session_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final directory = await getApplicationSupportDirectory();
    final env = await AppEnv.load();
    final questionsUri = env.questionsCatalogUri;
    final activitiesUri = env.activitiesCatalogUri;
    final appConfigUri = env.appConfigUri;

    final questionRepo = CachedQuestionRepository(
      cacheFile: File('${directory.path}/question_catalog.json'),
      download: questionsUri != null
          ? (etag) => downloadCatalog(questionsUri, etag)
          : null,
    );

    final activityRepo = CachedActivityRepository(
      cacheFile: File('${directory.path}/activity_catalog.json'),
      download: activitiesUri != null
          ? (etag) => downloadActivityCatalog(activitiesUri, etag)
          : null,
    );

    final appConfigRepo = CachedAppConfigRepository(
      cacheFile: File('${directory.path}/app_config.json'),
      download: appConfigUri != null
          ? (etag) => downloadAppConfig(appConfigUri, etag)
          : null,
    );

    final feedbackStorage = FileFeedbackStorage(
      storageFile: File(
        '${directory.path}/${FileFeedbackStorage.defaultFileName}',
      ),
    );

    final publicKeyValue = env.licensePublicKey;
    final linkHost = env.linkHost;
    SimplePublicKey? publicKey;
    try {
      final bytes = base64Url.decode(base64Url.normalize(publicKeyValue));
      if (bytes.length == 32) {
        publicKey = SimplePublicKey(bytes, type: KeyPairType.ed25519);
      }
    } catch (_) {
      // An unconfigured build cannot silently bypass activation.
    }

    runApp(
      WefaqApp(
        questionRepository: questionRepo,
        questionUpdates: questionRepo,
        activityRepository: activityRepo,
        appConfigRepository: appConfigRepo,
        feedbackStorage: feedbackStorage,
        onSyncContent: () async {
          try {
            await activityRepo.update();
          } catch (_) {}
          try {
            await appConfigRepo.refresh();
          } catch (_) {}
        },
        activationLinkHost: linkHost,
        activationLinks: linkHost.isEmpty ? null : AppLinks().uriLinkStream,
        activationService: OfflineActivationService(
          storage: const SecureActivationStorage(FlutterSecureStorage()),
          publicKey: publicKey,
          trialDuration: OfflineActivationService.defaultTrialDuration,
        ),
        sessionStorage: FileSessionStorage(
          storageFile: File('${directory.path}/session.json'),
        ),
        favoritesStorage: FileFavoritesStorage(
          storageFile: File('${directory.path}/favorites.json'),
        ),
        historyStorage: FileQuestionHistoryStorage(
          storageFile: File('${directory.path}/history.json'),
        ),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('تعذر فتح مساحة حفظ التطبيق. يرجى إعادة المحاولة.'),
          ),
        ),
      ),
    );
  }
}

class WefaqApp extends StatelessWidget {
  const WefaqApp({
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
    this.activationLinkHost = '',
    this.activationLinks,
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
  final String activationLinkHost;
  final Stream<Uri>? activationLinks;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'وفاق',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    home: activationService == null
        ? HomeScreen(
            sessionStorage: sessionStorage,
            questionRepository: questionRepository,
            favoritesStorage: favoritesStorage,
            historyStorage: historyStorage,
            licenseRepository: licenseRepository,
            questionUpdates: questionUpdates,
            activityRepository: activityRepository,
            appConfigRepository: appConfigRepository,
            feedbackStorage: feedbackStorage,
            onSyncContent: onSyncContent,
          )
        : OfflineActivationGate(
            service: activationService!,
            linkHost: activationLinkHost,
            links: activationLinks,
            child: HomeScreen(
              sessionStorage: sessionStorage,
              questionRepository: questionRepository,
              favoritesStorage: favoritesStorage,
              historyStorage: historyStorage,
              activationService: activationService,
              questionUpdates: questionUpdates,
              activityRepository: activityRepository,
              appConfigRepository: appConfigRepository,
              feedbackStorage: feedbackStorage,
              onSyncContent: onSyncContent,
            ),
          ),
  );
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'features/favorites/data/favorites_storage.dart';
import 'features/favorites/domain/repositories/favorites_storage.dart';
import 'features/home/home_screen.dart';
import 'features/licensing/licensing_data.dart';
import 'features/sessions/session_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final directory = await getApplicationSupportDirectory();
    runApp(
      WefaqApp(
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
  });

  final SessionStorage? sessionStorage;
  final QuestionRepository? questionRepository;
  final FavoritesStorage? favoritesStorage;
  final QuestionHistoryStorage? historyStorage;
  final LicenseRepository? licenseRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'وفاق',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    home: HomeScreen(
      sessionStorage: sessionStorage,
      questionRepository: questionRepository,
      favoritesStorage: favoritesStorage,
      historyStorage: historyStorage,
      licenseRepository: licenseRepository,
    ),
  );
}

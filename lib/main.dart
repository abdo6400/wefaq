import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'features/home/home_screen.dart';

void main() => runApp(const WefaqApp());

class WefaqApp extends StatelessWidget {
  const WefaqApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'وفاق',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    home: const HomeScreen(),
  );
}

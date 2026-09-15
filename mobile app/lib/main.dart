import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'core/service_locator.dart';

/// Backend API base URL.
///
/// Defaults to the local Laravel dev server (matches `php artisan serve` +
/// backendweb's own README quick-start), which only works on an emulator/
/// simulator talking to a backend running on the SAME machine — a real
/// device can never reach 127.0.0.1 on your laptop.
///
/// For a real build, override at build time instead of editing this file:
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://your-api.up.railway.app/api/v1
///   flutter run \
///     --dart-define=API_BASE_URL=https://your-api.up.railway.app/api/v1
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api/v1',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Portrait-only, matching the mobile-first RESIVYN design system.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialise the service locator — connects to the backend if reachable.
  await Services.init(apiBaseUrl);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('hi'),
        Locale('ru'),
        Locale('fr'),
        Locale('es'),
        Locale('tr'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      // Several locales (hi/ru/fr/es/tr/pt) only have partial coverage so
      // far. Without this, a missing key renders as the raw key string
      // (e.g. "account_settings") instead of falling back to readable
      // English text.
      useFallbackTranslations: true,
      child: const ResivynApp(),
    ),
  );
}

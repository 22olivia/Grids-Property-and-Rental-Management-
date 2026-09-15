import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'core/service_locator.dart';

/// Backend API base URL.
/// Change this to point to your running Laravel backend.
const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';

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
      child: const ResivynApp(),
    ),
  );
}

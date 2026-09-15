import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Language selection screen — choose app language with persistence.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = <_Lang>[
    _Lang('English', 'en', 'Default language', Icons.language_rounded),
    _Lang('العربية', 'ar', 'Arabic', Icons.language_rounded),
    _Lang('हिन्दी', 'hi', 'Hindi', Icons.language_rounded),
    _Lang('Русский', 'ru', 'Russian', Icons.language_rounded),
    _Lang('Français', 'fr', 'French', Icons.language_rounded),
    _Lang('Español', 'es', 'Spanish', Icons.language_rounded),
    _Lang('Türkçe', 'tr', 'Turkish', Icons.language_rounded),
    _Lang('Português', 'pt', 'Portuguese', Icons.language_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('language'.tr(), style: RT.h2),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x8),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('app_language'.tr(), style: RT.h2),
                  const SizedBox(height: RS.x4),
                  Text(
                    'choose_language'.tr(),
                    style: RT.caption,
                  ),
                  const SizedBox(height: RS.x20),
                  for (var i = 0; i < _languages.length; i++) ...[
                    _LanguageTile(
                      lang: _languages[i],
                      selected: _languages[i].code == currentLocale.languageCode,
                      onTap: () async {
                        final langName = _languages[i].name;
                        final newLocale = Locale(_languages[i].code);
                        await context.setLocale(newLocale);
                        if (!mounted) return;
                        toast(
                          context,
                          'language_changed'.tr(
                              namedArgs: {'language': langName}),
                          icon: Icons.language_rounded,
                        );
                      },
                    ),
                    if (i != _languages.length - 1) const ThinDivider(inset: 52),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x24),

          // ---- Info note ----
          Padding(
            padding: RS.page,
            child: InfoBanner(
              title: 'more_languages_coming'.tr(),
              body: 'more_languages_desc'.tr(),
              icon: Icons.info_outline_rounded,
            ),
          ),

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }
}

class _Lang {
  const _Lang(this.name, this.code, this.subtitle, this.icon);
  final String name;
  final String code;
  final String subtitle;
  final IconData icon;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final _Lang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: RR.inner,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RS.x12),
        child: Row(
          children: [
            IconBubble(
              lang.icon,
              tint: selected ? RC.teal : RC.textSecondary,
              size: 36,
              solid: selected,
            ),
            const SizedBox(width: RS.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.name, style: RT.title),
                  const SizedBox(height: 2),
                  Text(lang.subtitle, style: RT.captionSm),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 24,
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_circle_rounded,
                      size: 22, color: RC.teal)
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: RC.borderStrong, width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

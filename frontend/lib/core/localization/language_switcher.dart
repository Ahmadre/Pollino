import 'package:flutter/material.dart';
import 'package:pollino/core/localization/i18n_service.dart';

/// Widget für die Sprachwahl
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  Future<void> _changeLanguage(String locale) async {
    final currentLocale = I18nService.instance.currentLocale;
    if (locale != currentLocale) {
      await I18nService.instance.changeLocale(locale);
      // setState() nicht mehr nötig - MyApp reagiert automatisch über den Stream
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: I18nService.instance.localeStream,
      initialData: I18nService.instance.currentLocale,
      builder: (context, snapshot) {
        final currentLocale = snapshot.data ?? I18nService.instance.currentLocale;

        return PopupMenuButton<String>(
          onSelected: _changeLanguage,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _getLanguageDisplayName(currentLocale),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'de_DE',
              child: Row(
                children: [
                  const Text('🇩🇪'),
                  const SizedBox(width: 8),
                  const Text('Deutsch'),
                  const Spacer(),
                  if (currentLocale == 'de_DE') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'en_GB',
              child: Row(
                children: [
                  const Text('🇬🇧'),
                  const SizedBox(width: 8),
                  const Text('English'),
                  const Spacer(),
                  if (currentLocale == 'en_GB') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'fr_FR',
              child: Row(
                children: [
                  const Text('🇫🇷'),
                  const SizedBox(width: 8),
                  const Text('Français'),
                  const Spacer(),
                  if (currentLocale == 'fr_FR') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'es_ES',
              child: Row(
                children: [
                  const Text('🇪🇸'),
                  const SizedBox(width: 8),
                  const Text('Español'),
                  const Spacer(),
                  if (currentLocale == 'es_ES') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'ja_JP',
              child: Row(
                children: [
                  const Text('🇯🇵'),
                  const SizedBox(width: 8),
                  const Text('日本語'),
                  const Spacer(),
                  if (currentLocale == 'ja_JP') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'ar_SA',
              child: Row(
                children: [
                  const Text('🇸🇦'),
                  const SizedBox(width: 8),
                  const Text('العربية'),
                  const Spacer(),
                  if (currentLocale == 'ar_SA') Icon(Icons.check, color: Colors.green[600], size: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLanguageDisplayName(String locale) {
    switch (locale) {
      case 'de_DE':
        return 'DE';
      case 'en_GB':
        return 'EN';
      case 'fr_FR':
        return 'FR';
      case 'es_ES':
        return 'ES';
      case 'ja_JP':
        return 'JP';
      case 'ar_SA':
        return 'AR';
      default:
        return 'EN';
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class I18nService {
  static I18nService? _instance;
  static I18nService get instance => _instance ??= I18nService._internal();
  I18nService._internal();

  Map<String, dynamic> _translations = {};
  String _currentLocale = defaultLocale;

  /// StreamController für Locale-Änderungen
  final _localeController = StreamController<String>.broadcast();

  /// Stream für Locale-Änderungen
  Stream<String> get localeStream => _localeController.stream;

  /// Preference-Key für gespeicherte Sprache
  static const String _localePreferenceKey = 'selected_locale';

  /// Verfügbare Sprachen
  static const List<String> supportedLocales = ['de_DE', 'en_GB', 'fr_FR', 'es_ES', 'ja_JP', 'ar_SA'];

  /// Standard-Locale (Fallback)
  static const String defaultLocale = 'en_GB';

  /// Aktuelles Locale
  String get currentLocale => _currentLocale;

  /// Prüft ob die aktuelle Sprache RTL (Rechts-nach-Links) ist
  bool get isRTL => _currentLocale.startsWith('ar');

  /// Gibt die Textrichtung für die aktuelle Sprache zurück
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Ermittelt die beste unterstützte Sprache basierend auf der System-Locale
  static String getSystemLocale() {
    try {
      // Hole die System-Locale vom Gerät/Browser
      final systemLocales = PlatformDispatcher.instance.locales;

      if (systemLocales.isNotEmpty) {
        for (final systemLocale in systemLocales) {
          // Konvertiere Flutter Locale zu unserem Format
          final localeString = '${systemLocale.languageCode}_${systemLocale.countryCode?.toUpperCase() ?? ''}';

          // Prüfe exakte Übereinstimmung
          if (supportedLocales.contains(localeString)) {
            print('System-Locale gefunden: $localeString');
            return localeString;
          }

          // Prüfe nur Sprachcode (z.B. 'de' -> 'de_DE')
          switch (systemLocale.languageCode) {
            case 'de':
              print('Deutsche Sprache erkannt, verwende de_DE');
              return 'de_DE';
            case 'en':
              print('Englische Sprache erkannt, verwende en_GB');
              return 'en_GB';
            case 'fr':
              print('Französische Sprache erkannt, verwende fr_FR');
              return 'fr_FR';
            case 'es':
              print('Spanische Sprache erkannt, verwende es_ES');
              return 'es_ES';
            case 'ja':
              print('Japanische Sprache erkannt, verwende ja_JP');
              return 'ja_JP';
            case 'ar':
              print('Arabische Sprache erkannt, verwende ar_SA');
              return 'ar_SA';
          }
        }
      }

      print('Keine unterstützte System-Locale gefunden, verwende Fallback: $defaultLocale');
      return defaultLocale;
    } catch (e) {
      print('Fehler beim Ermitteln der System-Locale: $e, verwende Fallback: $defaultLocale');
      return defaultLocale;
    }
  }

  /// Initialisierung des i18n Service
  Future<void> init(String locale) async {
    _currentLocale = locale;
    await _loadTranslations(locale);
  }

  /// Initialisierung mit automatischer System-Locale-Erkennung und gespeicherter Präferenz
  Future<void> initWithSystemLocale() async {
    // Prüfe zunächst ob eine Sprache gespeichert ist
    final savedLocale = await _getSavedLocale();

    if (savedLocale != null && supportedLocales.contains(savedLocale)) {
      print('Gespeicherte Sprache gefunden: $savedLocale');
      await init(savedLocale);
    } else {
      // Verwende System-Locale falls keine Sprache gespeichert ist
      final systemLocale = getSystemLocale();
      await init(systemLocale);
    }
  }

  /// Lade gespeicherte Sprache aus SharedPreferences
  Future<String?> _getSavedLocale() async {
    try {
      final box = await Hive.openBox('app_prefs');
      final value = box.get(_localePreferenceKey);
      if (value is String) return value;
      return null;
    } catch (e) {
      print('Fehler beim Laden der gespeicherten Sprache: $e');
      return null;
    }
  }

  /// Speichere Sprache in SharedPreferences
  Future<void> _saveLocale(String locale) async {
    try {
      final box = await Hive.openBox('app_prefs');
      await box.put(_localePreferenceKey, locale);
      print('Sprache gespeichert: $locale');
    } catch (e) {
      print('Fehler beim Speichern der Sprache: $e');
    }
  }

  /// Lade Übersetzungen für das gegebene Locale
  Future<void> _loadTranslations(String locale) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/$locale.json',
      );
      _translations = json.decode(jsonString);
    } catch (e) {
      print('Fehler beim Laden der Übersetzungen für $locale: $e');

      // Fallback auf Standard-Locale
      if (locale != defaultLocale) {
        await _loadTranslations(defaultLocale);
      }
    }
  }

  /// Wechsle die Sprache und speichere sie persistent
  Future<void> changeLocale(String locale) async {
    if (supportedLocales.contains(locale) && locale != _currentLocale) {
      await init(locale);
      await _saveLocale(locale); // Speichere die neue Sprache
      _localeController.add(locale); // Benachrichtige Listener über die Änderung
    }
  }

  /// Übersetze einen Schlüssel
  String translate(String key, {Map<String, dynamic>? params}) {
    final translation = _getNestedTranslation(key);

    if (translation == null) {
      print('Übersetzung nicht gefunden für: $key');
      return key;
    }

    // Ersetze Parameter in der Übersetzung
    String result = translation;
    if (params != null) {
      params.forEach((paramKey, value) {
        result = result.replaceAll('{{$paramKey}}', value.toString());
      });
    }

    return result;
  }

  /// Hole verschachtelte Übersetzung über Punkt-Notation
  String? _getNestedTranslation(String key) {
    final keys = key.split('.');
    dynamic current = _translations;

    for (final k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }

  /// Übersetze mit Pluralisierung
  String translatePlural(String key, int count, {Map<String, dynamic>? params}) {
    String pluralKey;

    switch (_currentLocale.substring(0, 2)) {
      case 'de': // Deutsch: 1 = singular, alles andere = plural
      case 'en': // Englisch: 1 = singular, alles andere = plural
      case 'es': // Spanisch: 1 = singular, alles andere = plural
        pluralKey = count == 1 ? key : '${key}_plural';
        break;

      case 'fr': // Französisch: 0,1 = singular, alles andere = plural
        pluralKey = (count == 0 || count == 1) ? key : '${key}_plural';
        break;

      case 'ja': // Japanisch: keine Pluralisierung
        pluralKey = key;
        break;

      case 'ar': // Arabisch: komplexe Pluralisierungsregeln
        if (count == 0) {
          pluralKey = '${key}_zero'; // Zero form
        } else if (count == 1) {
          pluralKey = key; // Singular
        } else if (count == 2) {
          pluralKey = '${key}_dual'; // Dual form
        } else if (count >= 3 && count <= 10) {
          pluralKey = '${key}_few'; // Few form
        } else {
          pluralKey = '${key}_many'; // Many form
        }
        break;

      default: // Standard: Englische Regeln
        pluralKey = count == 1 ? key : '${key}_plural';
        break;
    }

    final translation = translate(pluralKey, params: params);

    // Fallback-Hierarchie für Arabisch
    if (translation == pluralKey && pluralKey != key && _currentLocale.startsWith('ar')) {
      // Versuche andere arabische Pluralformen als Fallback
      final fallbacks = ['${key}_plural', '${key}_many', '${key}_few', key];
      for (final fallback in fallbacks) {
        final fallbackTranslation = translate(fallback, params: params);
        if (fallbackTranslation != fallback) {
          return fallbackTranslation;
        }
      }
    }

    // Standard-Fallback wenn Plural-Version nicht existiert
    if (translation == pluralKey && pluralKey != key) {
      return translate(key, params: params);
    }

    return translation;
  }

  /// Formatiere Zeit mit korrekter Pluralisierung
  String formatTime(int value, String unit) {
    final timeKey = 'time.units.$unit';
    final translatedUnit = translatePlural(timeKey, value);
    return '$value $translatedUnit';
  }

  /// Prüfe ob Übersetzung existiert
  bool hasTranslation(String key) {
    return _getNestedTranslation(key) != null;
  }

  /// Hole alle Übersetzungen für einen Prefix
  Map<String, String> getTranslationsForPrefix(String prefix) {
    final result = <String, String>{};
    _collectTranslationsWithPrefix(_translations, prefix, '', result);
    return result;
  }

  void _collectTranslationsWithPrefix(
    Map<String, dynamic> translations,
    String targetPrefix,
    String currentPrefix,
    Map<String, String> result,
  ) {
    translations.forEach((key, value) {
      final fullKey = currentPrefix.isEmpty ? key : '$currentPrefix.$key';

      if (value is String) {
        if (fullKey.startsWith(targetPrefix)) {
          result[fullKey] = value;
        }
      } else if (value is Map<String, dynamic>) {
        _collectTranslationsWithPrefix(value, targetPrefix, fullKey, result);
      }
    });
  }

  /// Debug-Funktion: Zeige alle verfügbaren Schlüssel
  void debugPrintAllKeys() {
    print('=== Alle verfügbaren Übersetzungsschlüssel ===');
    _printKeys(_translations, '');
  }

  void _printKeys(Map<String, dynamic> translations, String prefix) {
    translations.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is String) {
        print('$fullKey: $value');
      } else if (value is Map<String, dynamic>) {
        _printKeys(value, fullKey);
      }
    });
  }
}

/// Extension für einfache Übersetzungen in Widgets
extension TranslationExtension on String {
  String tr({Map<String, dynamic>? params}) {
    return I18nService.instance.translate(this, params: params);
  }

  String trPlural(int count, {Map<String, dynamic>? params}) {
    return I18nService.instance.translatePlural(this, count, params: params);
  }
}

/// Widget für automatische Übersetzungen basierend auf Locale-Änderungen
class TranslationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const TranslationBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<TranslationBuilder> createState() => _TranslationBuilderState();
}

class _TranslationBuilderState extends State<TranslationBuilder> {
  String _currentLocale = I18nService.instance.currentLocale;

  @override
  void initState() {
    super.initState();
    // Hier könntest du einen Listener hinzufügen, wenn der Service
    // Änderungsbenachrichtigungen unterstützt
  }

  @override
  Widget build(BuildContext context) {
    // Prüfe ob sich das Locale geändert hat
    if (_currentLocale != I18nService.instance.currentLocale) {
      _currentLocale = I18nService.instance.currentLocale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    return widget.builder(context);
  }
}

/// Erweiterung für I18nService Cleanup
extension I18nServiceCleanup on I18nService {
  /// Schließt den StreamController (für Tests oder App-Ende)
  void dispose() {
    if (!_localeController.isClosed) {
      _localeController.close();
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localizationServiceProvider = Provider<LocalizationService>((ref) => LocalizationService());

class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
  });
}

class LocalizedContent {
  final String id;
  final String contentId;
  final String languageCode;
  final Map<String, String> translations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String translatedBy;
  final bool isAutoTranslated;

  LocalizedContent({
    required this.id,
    required this.contentId,
    required this.languageCode,
    required this.translations,
    required this.createdAt,
    required this.updatedAt,
    required this.translatedBy,
    required this.isAutoTranslated,
  });

  factory LocalizedContent.fromMap(Map<String, dynamic> map, String id) {
    return LocalizedContent(
      id: id,
      contentId: map['contentId'] ?? '',
      languageCode: map['languageCode'] ?? '',
      translations: Map<String, String>.from(map['translations'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      translatedBy: map['translatedBy'] ?? '',
      isAutoTranslated: map['isAutoTranslated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'languageCode': languageCode,
      'translations': translations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'translatedBy': translatedBy,
      'isAutoTranslated': isAutoTranslated,
    };
  }
}

class LocalizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  // Supported languages
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    SupportedLanguage(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: '🇹🇿',
    ),
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    SupportedLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    SupportedLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    SupportedLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    SupportedLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    SupportedLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    SupportedLanguage(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
    SupportedLanguage(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
  ];

  // Default translations for common UI elements
  static const Map<String, Map<String, String>> defaultTranslations = {
    'en': {
      'app_name': 'Zanzibar Tourism',
      'welcome': 'Welcome',
      'home': 'Home',
      'sites': 'Sites',
      'bookings': 'Bookings',
      'marketplace': 'Marketplace',
      'favorites': 'Favorites',
      'profile': 'Profile',
      'search': 'Search',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'remove': 'Remove',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'price': 'Price',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'book_now': 'Book Now',
      'add_to_cart': 'Add to Cart',
      'view_details': 'View Details',
      'cultural_sites': 'Cultural Sites',
      'tours': 'Tours',
      'products': 'Products',
      'spices': 'Spices',
      'handcrafts': 'Handcrafts',
      'stone_town': 'Stone Town',
      'beaches': 'Beaches',
      'history': 'History',
      'culture': 'Culture',
    },
    'sw': {
      'app_name': 'Utalii wa Zanzibar',
      'welcome': 'Karibu',
      'home': 'Nyumbani',
      'sites': 'Maeneo',
      'bookings': 'Mahifadhi',
      'marketplace': 'Soko',
      'favorites': 'Vipendwa',
      'profile': 'Wasifu',
      'search': 'Tafuta',
      'notifications': 'Arifa',
      'settings': 'Mipangilio',
      'login': 'Ingia',
      'register': 'Jisajili',
      'logout': 'Toka',
      'save': 'Hifadhi',
      'cancel': 'Ghairi',
      'delete': 'Futa',
      'edit': 'Hariri',
      'add': 'Ongeza',
      'remove': 'Ondoa',
      'loading': 'Inapakia...',
      'error': 'Hitilafu',
      'success': 'Mafanikio',
      'price': 'Bei',
      'rating': 'Ukadiriaji',
      'reviews': 'Maoni',
      'book_now': 'Hifadhi Sasa',
      'add_to_cart': 'Ongeza Kwenye Kikapu',
      'view_details': 'Ona Maelezo',
      'cultural_sites': 'Maeneo ya Kitamaduni',
      'tours': 'Ziara',
      'products': 'Bidhaa',
      'spices': 'Viungo',
      'handcrafts': 'Ufundi wa Mikono',
      'stone_town': 'Mji wa Mawe',
      'beaches': 'Fukizo',
      'history': 'Historia',
      'culture': 'Utamaduni',
    },
    'ar': {
      'app_name': 'سياحة زنجبار',
      'welcome': 'مرحباً',
      'home': 'الرئيسية',
      'sites': 'المواقع',
      'bookings': 'الحجوزات',
      'marketplace': 'السوق',
      'favorites': 'المفضلة',
      'profile': 'الملف الشخصي',
      'search': 'البحث',
      'notifications': 'الإشعارات',
      'settings': 'الإعدادات',
      'login': 'تسجيل الدخول',
      'register': 'التسجيل',
      'logout': 'تسجيل الخروج',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'remove': 'إزالة',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'price': 'السعر',
      'rating': 'التقييم',
      'reviews': 'المراجعات',
      'book_now': 'احجز الآن',
      'add_to_cart': 'أضف إلى السلة',
      'view_details': 'عرض التفاصيل',
      'cultural_sites': 'المواقع الثقافية',
      'tours': 'الجولات',
      'products': 'المنتجات',
      'spices': 'التوابل',
      'handcrafts': 'الحرف اليدوية',
      'stone_town': 'المدينة الحجرية',
      'beaches': 'الشواطئ',
      'history': 'التاريخ',
      'culture': 'الثقافة',
    },
  };

  // Get current language
  Future<String> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      return _defaultLanguage;
    }
  }

  // Set current language
  Future<void> setCurrentLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      throw Exception('Failed to set language: $e');
    }
  }

  // Get supported language by code
  SupportedLanguage? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  // Get translation for a key
  String translate(String key, [String? languageCode]) {
    final currentLang = languageCode ?? _defaultLanguage;
    
    // Check default translations first
    if (defaultTranslations.containsKey(currentLang) &&
        defaultTranslations[currentLang]!.containsKey(key)) {
      return defaultTranslations[currentLang]![key]!;
    }
    
    // Fallback to English if translation not found
    if (currentLang != 'en' && 
        defaultTranslations.containsKey('en') &&
        defaultTranslations['en']!.containsKey(key)) {
      return defaultTranslations['en']![key]!;
    }
    
    // Return key if no translation found
    return key;
  }

  // Add or update translation for content
  Future<void> addTranslation({
    required String contentId,
    required String languageCode,
    required Map<String, String> translations,
    required String translatedBy,
    bool isAutoTranslated = false,
  }) async {
    try {
      final translationId = '${contentId}_$languageCode';
      
      final localizedContent = LocalizedContent(
        id: translationId,
        contentId: contentId,
        languageCode: languageCode,
        translations: translations,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        translatedBy: translatedBy,
        isAutoTranslated: isAutoTranslated,
      );

      await _firestore
          .collection('localized_content')
          .doc(translationId)
          .set(localizedContent.toMap());
    } catch (e) {
      throw Exception('Failed to add translation: $e');
    }
  }

  // Get translation for content
  Future<LocalizedContent?> getTranslation(String contentId, String languageCode) async {
    try {
      final translationId = '${contentId}_$languageCode';
      final doc = await _firestore
          .collection('localized_content')
          .doc(translationId)
          .get();

      if (!doc.exists) return null;

      return LocalizedContent.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Get all translations for content
  Future<List<LocalizedContent>> getContentTranslations(String contentId) async {
    try {
      final snapshot = await _firestore
          .collection('localized_content')
          .where('contentId', isEqualTo: contentId)
          .get();

      return snapshot.docs.map((doc) {
        return LocalizedContent.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get localized text for content field
  Future<String> getLocalizedText({
    required String contentId,
    required String fieldName,
    required String defaultText,
    String? languageCode,
  }) async {
    try {
      final currentLang = languageCode ?? await getCurrentLanguage();
      
      if (currentLang == _defaultLanguage) {
        return defaultText;
      }

      final translation = await getTranslation(contentId, currentLang);
      
      if (translation != null && translation.translations.containsKey(fieldName)) {
        return translation.translations[fieldName]!;
      }

      return defaultText;
    } catch (e) {
      return defaultText;
    }
  }

  // Delete translation
  Future<void> deleteTranslation(String contentId, String languageCode) async {
    try {
      final translationId = '${contentId}_$languageCode';
      await _firestore.collection('localized_content').doc(translationId).delete();
    } catch (e) {
      throw Exception('Failed to delete translation: $e');
    }
  }

  // Get translation progress for content
  Future<Map<String, bool>> getTranslationProgress(String contentId) async {
    try {
      final translations = await getContentTranslations(contentId);
      final progress = <String, bool>{};

      for (final lang in supportedLanguages) {
        progress[lang.code] = translations.any((t) => t.languageCode == lang.code);
      }

      return progress;
    } catch (e) {
      return {};
    }
  }

  // Get locale from language code
  Locale getLocale(String languageCode) {
    return Locale(languageCode);
  }

  // Check if language is RTL
  bool isRTL(String languageCode) {
    final language = getLanguageByCode(languageCode);
    return language?.isRTL ?? false;
  }

  // Get text direction
  TextDirection getTextDirection(String languageCode) {
    return isRTL(languageCode) ? TextDirection.rtl : TextDirection.ltr;
  }

  // Auto-translate content (placeholder for future implementation)
  Future<Map<String, String>> autoTranslateContent({
    required Map<String, String> content,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    // This would integrate with a translation service like Google Translate
    // For now, return the original content
    return content;
  }

  // Get translation statistics
  Future<Map<String, dynamic>> getTranslationStatistics() async {
    try {
      final snapshot = await _firestore.collection('localized_content').get();
      
      Map<String, int> languageStats = {};
      int totalTranslations = 0;
      int autoTranslations = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final languageCode = data['languageCode'] as String? ?? '';
        final isAuto = data['isAutoTranslated'] as bool? ?? false;

        languageStats[languageCode] = (languageStats[languageCode] ?? 0) + 1;
        totalTranslations++;
        
        if (isAuto) {
          autoTranslations++;
        }
      }

      return {
        'totalTranslations': totalTranslations,
        'autoTranslations': autoTranslations,
        'manualTranslations': totalTranslations - autoTranslations,
        'languageStats': languageStats,
        'supportedLanguages': supportedLanguages.length,
      };
    } catch (e) {
      return {};
    }
  }
}

class VoxLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const VoxLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class SupportedLanguages {
  static const List<VoxLanguage> list = [
    VoxLanguage(code: "auto", name: "Auto Detect", nativeName: "Auto Detect (30+ Langs)", flag: "🌐"),
    VoxLanguage(code: "en", name: "English", nativeName: "English", flag: "🇺🇸"),
    VoxLanguage(code: "zh", name: "Chinese (Mandarin)", nativeName: "中文 (普通话)", flag: "🇨🇳"),
    VoxLanguage(code: "zh-yue", name: "Cantonese", nativeName: "粤语 (广东话)", flag: "🇭🇰"),
    VoxLanguage(code: "zh-sc", name: "Sichuanese", nativeName: "四川话", flag: "🇨🇳"),
    VoxLanguage(code: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸"),
    VoxLanguage(code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷"),
    VoxLanguage(code: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪"),
    VoxLanguage(code: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵"),
    VoxLanguage(code: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷"),
    VoxLanguage(code: "hi", name: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳"),
    VoxLanguage(code: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺"),
    VoxLanguage(code: "ar", name: "Arabic", nativeName: "العربية", flag: "🇸🇦"),
    VoxLanguage(code: "pt", name: "Portuguese", nativeName: "Português", flag: "🇧🇷"),
    VoxLanguage(code: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹"),
    VoxLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands", flag: "🇳🇱"),
    VoxLanguage(code: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱"),
    VoxLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe", flag: "🇹🇷"),
    VoxLanguage(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", flag: "🇮🇩"),
    VoxLanguage(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳"),
    VoxLanguage(code: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭"),
    VoxLanguage(code: "sv", name: "Swedish", nativeName: "Svenska", flag: "🇸🇪"),
    VoxLanguage(code: "da", name: "Danish", nativeName: "Dansk", flag: "🇩🇰"),
    VoxLanguage(code: "fi", name: "Finnish", nativeName: "Suomi", flag: "🇫🇮"),
    VoxLanguage(code: "no", name: "Norwegian", nativeName: "Norsk", flag: "🇳🇴"),
    VoxLanguage(code: "el", name: "Greek", nativeName: "Ελληνικά", flag: "🇬🇷"),
    VoxLanguage(code: "he", name: "Hebrew", nativeName: "עברית", flag: "🇮🇱"),
    VoxLanguage(code: "ms", name: "Malay", nativeName: "Bahasa Melayu", flag: "🇲🇾"),
    VoxLanguage(code: "tl", name: "Tagalog", nativeName: "Filipino", flag: "🇵🇭"),
    VoxLanguage(code: "sw", name: "Swahili", nativeName: "Kiswahili", flag: "🇰🇪"),
  ];
}

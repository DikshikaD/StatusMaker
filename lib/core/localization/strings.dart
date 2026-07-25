import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny app-wide localization. [lang] drives every screen; changing it rebuilds
/// the app (see main.dart) so all `S.t(...)` lookups return the new language.
class S {
  static final ValueNotifier<String> lang = ValueNotifier<String>('en');

  static const String _prefKey = 'app_language';

  static bool get isHi => lang.value == 'hi';

  /// Loads the saved language before the UI builds. Call once in `main()`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && (saved == 'en' || saved == 'hi')) {
        lang.value = saved;
      }
    } catch (_) {
      // If preferences can't be read, fall back to the default language.
    }
  }

  /// Sets the language and persists the choice for next launch.
  static void set(String l) {
    lang.value = l;
    _persist(l);
  }

  static Future<void> _persist(String l) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, l);
    } catch (_) {
      // Persisting is best-effort; ignore storage errors.
    }
  }

  static String t(String key) {
    final v = _m[key];
    if (v == null) return key;
    return isHi ? v[1] : v[0];
  }

  /// Translates a category's display name (logic still uses the English name).
  static String cat(String name) => t('cat_$name');

  // [english, hindi]
  static const Map<String, List<String>> _m = {
    'app_name': ['Status Artist', 'स्टेटस आर्टिस्ट'],

    // bottom nav
    'nav_home': ['Home', 'होम'],
    'nav_explore': ['Explore', 'एक्सप्लोर'],
    'nav_create': ['Create', 'बनाएँ'],
    'nav_favorites': ['Favorites', 'पसंदीदा'],
    'nav_settings': ['Settings', 'सेटिंग्स'],

    // categories
    'cat_Good Morning': ['Good Morning', 'सुप्रभात'],
    'cat_Morning': ['Morning', 'सुबह'],
    'cat_Birthday': ['Birthday', 'जन्मदिन'],
    'cat_Festival': ['Festival', 'त्योहार'],
    'cat_Motivation': ['Motivation', 'प्रेरणा'],
    'cat_Love': ['Love', 'प्यार'],
    'cat_Business': ['Business', 'बिज़नेस'],
    'cat_Devotional': ['Devotional', 'भक्ति'],
    'cat_Suprabhat': ['Good Morning', 'शुभ प्रभात'],
    'cat_Good Night': ['Good Night', 'शुभ रात्रि'],
    'cat_Suvichar': ['Suvichar', 'सुविचार'],
    'cat_General': ['General', 'सामान्य'],

    // category picker (create flow)
    'choose_category': ['Choose a category', 'श्रेणी चुनें'],
    'choose_category_desc': [
      'We\'ll suggest matching quotes for you',
      'हम आपके लिए मिलती-जुलती पंक्तियाँ सुझाएँगे'
    ],

    // settings
    'settings_title': ['Settings', 'सेटिंग्स'],
    'language': ['Language', 'भाषा'],
    'language_desc': ['Choose your app language', 'ऐप की भाषा चुनें'],
    'english': ['English', 'English'],
    'hindi': ['हिंदी', 'हिंदी'],
    'appearance': ['Appearance', 'दिखावट'],
    'appearance_desc': [
      'Switch between light and dark theme',
      'लाइट और डार्क थीम के बीच स्विच करें'
    ],
    'theme': ['Theme', 'थीम'],
    'light_theme': ['Light', 'लाइट'],
    'dark_theme': ['Dark', 'डार्क'],
    'dark_mode': ['Dark mode', 'डार्क मोड'],
    'about': ['About', 'परिचय'],
    'version': ['Version', 'वर्शन'],
    'rate_us': ['Rate us', 'हमें रेट करें'],
    'share_app': ['Share app', 'ऐप शेयर करें'],

    // home
    'youre_caught_up': ['You\'re all caught up!', 'आप पूरी तरह अपडेटेड हैं!'],

    // explore
    'explore_title': ['Search Discovery', 'खोज'],
    'trending_searches': ['Trending Searches', 'ट्रेंडिंग खोज'],
    'discover_more': ['Discover More', 'और खोजें'],
    'filter': ['Filter', 'फ़िल्टर'],
    'search_hint': ['Search templates...', 'टेम्पलेट खोजें...'],
    'more_soon': ['More options coming soon', 'और विकल्प जल्द आ रहे हैं'],
    'filters_soon': ['Filters coming soon', 'फ़िल्टर जल्द आ रहे हैं'],

    // create
    'create_title': ['Create', 'बनाएँ'],
    'start_creating': ['Start creating', 'बनाना शुरू करें'],
    'start_creating_desc': [
      'Jump straight into the editor and design your status in seconds.',
      'सीधे एडिटर में जाएँ और सेकंडों में अपना स्टेटस डिज़ाइन करें।'
    ],
    'open_editor': ['Open Editor', 'एडिटर खोलें'],
    'themes': ['Themes', 'थीम'],
    'popular_templates': ['Popular Templates', 'लोकप्रिय टेम्पलेट'],
    'all': ['All', 'सभी'],
    'designs': ['designs', 'डिज़ाइन'],
    'trending_now': ['Trending now', 'अभी ट्रेंडिंग'],

    // favorites
    'favorites_title': ['Favorites', 'पसंदीदा'],
    'saved_templates': ['Saved Templates', 'सहेजे गए टेम्पलेट'],
    'my_creations': ['My Creations', 'मेरी रचनाएँ'],
    'fav_empty_title': ['No saved templates yet', 'अभी कोई सहेजा टेम्पलेट नहीं'],
    'fav_empty_msg': [
      'Tap the heart on any design you love and it\'ll show up here.',
      'किसी भी पसंदीदा डिज़ाइन पर हार्ट टैप करें, वह यहाँ दिखेगा।'
    ],
    'creations_empty_title': ['No creations yet', 'अभी कोई रचना नहीं'],
    'creations_empty_msg': [
      'Statuses you make will be saved here so you can find them anytime.',
      'आपके बनाए स्टेटस यहाँ सहेजे जाएँगे ताकि आप कभी भी पा सकें।'
    ],

    // onboarding
    'onb_title': [
      'Add your photo and\nmake it personal',
      'अपनी फ़ोटो जोड़ें और\nइसे ख़ास बनाएँ'
    ],
    'onb_desc': [
      'Easily drop your own photos into beautiful layouts created by world-class designers.',
      'अपनी फ़ोटो को शानदार लेआउट में आसानी से जोड़ें, जो बेहतरीन डिज़ाइनरों ने बनाए हैं।'
    ],
    'next': ['Next', 'आगे'],
    'skip': ['Skip', 'छोड़ें'],
    'choose_style': ['Choose your style', 'अपनी स्टाइल चुनें'],

    // onboarding — 3 steps
    'onb1_title': ['Ready-made designs', 'तैयार डिज़ाइन'],
    'onb1_desc': [
      'Hundreds of beautiful status templates for every mood, festival and moment.',
      'हर मूड, त्योहार और पल के लिए सैकड़ों सुंदर स्टेटस टेम्पलेट।'
    ],
    'onb2_title': ['Make it yours', 'इसे अपना बनाएँ'],
    'onb2_desc': [
      'Add your photo and change text, colors and fonts — everything is editable in a tap.',
      'अपनी फ़ोटो जोड़ें और टेक्स्ट, रंग व फ़ॉन्ट बदलें — सब कुछ एक टैप में एडिट करें।'
    ],
    'onb3_title': ['Save & share', 'सेव करें और शेयर करें'],
    'onb3_desc': [
      'Export in HD and share your status on WhatsApp and more in seconds.',
      'HD में सेव करें और अपना स्टेटस WhatsApp व अन्य ऐप पर पलभर में शेयर करें।'
    ],
    'get_started': ['Get Started', 'शुरू करें'],
    'splash_tagline': ['Create. Personalize. Share.', 'बनाएँ। सजाएँ। शेयर करें।'],

    // language popup
    'choose_language': ['Choose your language', 'अपनी भाषा चुनें'],
    'choose_language_desc': [
      'You can change this anytime in Settings.',
      'आप इसे कभी भी सेटिंग्स में बदल सकते हैं।'
    ],
    'continue_btn': ['Continue', 'जारी रखें'],

    // category
    'category_templates': ['Templates', 'टेम्पलेट'],
    'tap_design_hint': [
      'Tap a design to start — everything stays editable',
      'शुरू करने के लिए किसी डिज़ाइन पर टैप करें — सब कुछ एडिट होता है'
    ],

    // preview
    'preview_title': ['Status Preview', 'स्टेटस प्रीव्यू'],
    'customize': ['Customize', 'कस्टमाइज़ करें'],
    'drafts': ['Drafts', 'ड्राफ़्ट'],
    'saved_device': ['Saved to your device', 'आपके डिवाइस में सेव हो गया'],
    'sharing': ['Sharing…', 'शेयर हो रहा है…'],
    'opening_drafts': ['Opening drafts…', 'ड्राफ़्ट खुल रहे हैं…'],

    // editor / common actions
    'save': ['Save', 'सेव'],
    'share': ['Share', 'शेयर'],
    'post': ['Post', 'पोस्ट'],
    'saved_cloud': ['Saved to your creations', 'आपकी रचनाओं में सेव हो गया'],
    'posted_public': [
      'Posted! It\'s now on the community feed.',
      'पोस्ट हो गया! अब यह कम्युनिटी फ़ीड में है।'
    ],
    'save_failed': [
      'Couldn\'t save. Please try again.',
      'सेव नहीं हो सका। कृपया फिर से प्रयास करें।'
    ],
    'delete_failed': [
      'Couldn\'t delete. Please try again.',
      'डिलीट नहीं हो सका। कृपया फिर से प्रयास करें।'
    ],
    'retry': ['Retry', 'फिर से करें'],
    'tag_public': ['Public', 'सार्वजनिक'],
    'tag_private': ['Private', 'निजी'],

    // home — community feed
    'community_feed': ['Community Feed', 'कम्युनिटी फ़ीड'],
    'feed_empty_title': ['No posts yet', 'अभी कोई पोस्ट नहीं'],
    'feed_empty_msg': [
      'Create a status and tap Post to share it with everyone here.',
      'एक स्टेटस बनाएँ और सबके साथ शेयर करने के लिए पोस्ट पर टैप करें।'
    ],
    'feed_error_title': ['Couldn\'t load feed', 'फ़ीड लोड नहीं हो सका'],
    'feed_error_msg': [
      'Something went wrong. Pull down to refresh.',
      'कुछ गड़बड़ हो गई। रिफ़्रेश करने के लिए नीचे खींचें।'
    ],
    'background': ['Background', 'बैकग्राउंड'],
    'photo': ['Photo', 'फ़ोटो'],
    'text': ['Text', 'टेक्स्ट'],
    'quotes': ['Quotes', 'कोट्स'],
    'one_tap_create': ['One-Tap Create', 'वन-टैप बनाएँ'],

    // status card menu
    'add_favorites': ['Add to Favorites', 'पसंदीदा में जोड़ें'],
    'not_interested': ['Not interested', 'रुचि नहीं'],
    'added_favorites': ['Added to Favorites', 'पसंदीदा में जोड़ा गया'],
    'fewer_like_this': ['We\'ll show fewer like this', 'ऐसे कम दिखाएँगे'],

    // editor — text toolbar
    'font': ['Font', 'फ़ॉन्ट'],
    'size': ['Size', 'साइज़'],
    'color': ['Color', 'रंग'],
    'bold': ['Bold', 'बोल्ड'],
    'italic': ['Italic', 'इटैलिक'],
    'align': ['Align', 'अलाइन'],
    'letter': ['Letter', 'अक्षर'],
    'line': ['Line', 'लाइन'],
    'letter_spacing': ['Letter spacing', 'अक्षर स्पेसिंग'],
    'line_spacing': ['Line spacing', 'लाइन स्पेसिंग'],

    // editor — image toolbar
    'shape': ['Shape', 'आकार'],
    'add_photo': ['Add photo', 'फ़ोटो जोड़ें'],
    'replace': ['Replace', 'बदलें'],
    'delete': ['Delete', 'हटाएँ'],
    'square': ['Square', 'चौकोर'],
    'rounded': ['Rounded', 'गोल किनारे'],
    'circle': ['Circle', 'गोल'],
    'oval': ['Oval', 'अंडाकार'],
    'heart': ['Heart', 'दिल'],

    // editor — background sheet
    'presets': ['Presets', 'प्रीसेट'],
    'gallery': ['Gallery', 'गैलरी'],
    'choose_gallery': ['Choose from Gallery', 'गैलरी से चुनें'],
    'none': ['None', 'कोई नहीं'],
    'colors': ['Colors', 'रंग'],
    'morning': ['Morning', 'सुप्रभात'],
    'festival': ['Festival', 'त्योहार'],
    'love': ['Love', 'प्यार'],
    'birthday': ['Birthday', 'जन्मदिन'],

    // editor — elements & frames
    'elements': ['Elements', 'एलिमेंट्स'],
    'shapes': ['Shapes', 'आकार'],
    'frames': ['Frames', 'फ्रेम'],
    'frame': ['Frame', 'फ्रेम'],
    'width': ['Width', 'चौड़ाई'],

    // editor — quotes sheet / starter
    'tap_quote': ['Tap a quote to add', 'जोड़ने के लिए कोट टैप करें'],
    'double_tap_edit': ['Double tap to edit', 'एडिट के लिए डबल टैप करें'],
  };
}

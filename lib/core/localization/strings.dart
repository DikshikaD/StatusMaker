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

    // push notifications
    //
    // The `_named` variants take the status title via {title}; see
    // PushService._localizedCopy, which falls back to the plain variant when
    // the payload carries no title. Kept in sync with the English copy in
    // supabase/functions/notify-on-like/index.ts, which words the tray
    // notification shown while the app is closed.
    'push_like_title': [
      'Someone liked your status ❤️',
      'किसी ने आपका स्टेटस पसंद किया ❤️'
    ],
    'push_like_body': [
      'Your status got a new like.',
      'आपके स्टेटस को नया लाइक मिला।'
    ],
    'push_like_body_named': [
      'Your status "{title}" got a new like.',
      'आपके स्टेटस "{title}" को नया लाइक मिला।'
    ],
    'push_remix_title': [
      'Someone remixed your template 🔁',
      'किसी ने आपका टेम्पलेट रीमिक्स किया 🔁'
    ],
    'push_remix_body': [
      'Someone used your template.',
      'किसी ने आपका टेम्पलेट इस्तेमाल किया।'
    ],
    'push_remix_body_named': [
      'Someone used your template "{title}".',
      'किसी ने आपका टेम्पलेट "{title}" इस्तेमाल किया।'
    ],

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
    'share_app_msg': [
      'Create beautiful statuses with Status Maker — get the app:',
      'स्टेटस मेकर के साथ सुंदर स्टेटस बनाएँ — ऐप डाउनलोड करें:'
    ],

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
    'no_results_title': ['No matches found', 'कोई नतीजा नहीं मिला'],
    'no_results_msg': [
      'Try a different word, or tap a trending search above.',
      'कोई और शब्द आज़माएँ, या ऊपर किसी ट्रेंडिंग खोज पर टैप करें।'
    ],
    'results_for': ['Results for', 'के लिए नतीजे'],

    // create
    'create_title': ['Create', 'बनाएँ'],
    'start_creating': ['Start creating', 'बनाना शुरू करें'],
    'start_creating_desc': [
      'Jump straight into the editor and design your status in seconds.',
      'सीधे एडिटर में जाएँ और सेकंडों में अपना स्टेटस डिज़ाइन करें।'
    ],
    'open_editor': ['Open Editor', 'एडिटर खोलें'],
    'themes': ['Themes', 'थीम'],
    'ready_templates': ['Ready Templates', 'तैयार टेम्पलेट'],
    'ready_templates_hint': [
      'Tap one to open it in the editor — everything is editable',
      'एडिटर में खोलने के लिए टैप करें — सब कुछ एडिट किया जा सकता है'
    ],

    // ready-template theme rows
    'grp_morning': ['Good Morning', 'शुभ प्रभात'],
    'grp_wishes': ['Wishes & Festivals', 'शुभकामनाएँ और त्योहार'],
    'grp_night': ['Good Night', 'शुभ रात्रि'],
    'grp_devotional': ['Devotional', 'भक्ति'],
    'grp_love': ['Love & Memories', 'प्यार और यादें'],
    'grp_quotes': ['Quotes', 'सुविचार'],
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
    'undo': ['Undo', 'पूर्ववत करें'],
    'redo': ['Redo', 'फिर से करें'],
    'save': ['Save', 'सेव'],
    'share': ['Share', 'शेयर'],
    'post': ['Post', 'पोस्ट'],

    // editor share sheet (WhatsApp / Instagram / Facebook / system chooser)
    'share_to': ['Share your status', 'अपना स्टेटस शेयर करें'],
    'share_to_msg': [
      'Pick where this design should go.',
      'चुनें कि यह डिज़ाइन कहाँ भेजना है।'
    ],
    'share_more': ['More apps', 'अन्य ऐप'],
    'not_installed': ['Not installed', 'इंस्टॉल नहीं है'],
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
    'tag_yours': ['Your status', 'आपका स्टेटस'],
    'edit': ['Edit', 'एडिट करें'],
    'something_wrong': ['Something went wrong', 'कुछ गड़बड़ हो गई'],
    'try_again_msg': [
      'Please try again in a moment.',
      'कृपया थोड़ी देर बाद फिर से प्रयास करें।'
    ],
    'deleted_ok': ['Deleted', 'डिलीट हो गया'],
    'cancel': ['Cancel', 'रद्द करें'],
    'discard': ['Discard', 'छोड़ दें'],
    'discard_changes_title': ['Discard Changes?', 'बदलाव छोड़ दें?'],
    'discard_changes_msg': [
      'You have unsaved changes. What would you like to do?',
      'आपके कुछ बदलाव सेव नहीं हुए हैं। आप क्या करना चाहेंगे?'
    ],
    'delete_status_title': ['Delete this?', 'इसे डिलीट करें?'],
    'delete_status_msg': [
      'This will permanently delete this creation. This can\'t be undone.',
      'यह रचना हमेशा के लिए डिलीट हो जाएगी। इसे वापस नहीं लाया जा सकता।'
    ],

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
    'adjust': ['Adjust', 'एडजस्ट'],
    'reposition_photo': ['Reposition Photo', 'फ़ोटो पुनः स्थिति'],
    'reposition_hint': [
      'Drag to move • Pinch to zoom',
      'खिसकाने के लिए ड्रैग करें • ज़ूम के लिए पिंच करें'
    ],
    'reset': ['Reset', 'रीसेट'],
    'done': ['Done', 'हो गया'],

    // locked (fixed) template editor
    'edit_text': ['Edit text', 'टेक्स्ट बदलें'],
    'remove_photo': ['Remove photo', 'फ़ोटो हटाएँ'],
    // Title of the words editor when the tapped slot is the design's name line.
    'your_name': ['Add your name', 'अपना नाम जोड़ें'],
    // Shown in the name slot until the user types their own — keep it short so
    // it fits every design's name line.
    'name_placeholder': ['— Your Name', '— आपका नाम'],
    'locked_select_hint': [
      'Tap the text or photo to change it — the layout stays fixed',
      'बदलने के लिए टेक्स्ट या फ़ोटो पर टैप करें — लेआउट फ़िक्स्ड रहेगा'
    ],

    // editor — background sheet
    'presets': ['Presets', 'प्रीसेट'],
    'gallery': ['Gallery', 'गैलरी'],
    'photo_backgrounds': ['Photo Backgrounds', 'फ़ोटो बैकग्राउंड'],
    'choose_gallery': ['Choose from Gallery', 'गैलरी से चुनें'],
    'none': ['None', 'कोई नहीं'],
    'colors': ['Colors', 'रंग'],
    'morning': ['Morning', 'सुप्रभात'],
    'festival': ['Festival', 'त्योहार'],
    'love': ['Love', 'प्यार'],
    'birthday': ['Birthday', 'जन्मदिन'],
    'bhakti': ['Bhakti', 'भक्ति'],
    'random': ['Random', 'विविध'],
    'backgrounds_offline': [
      'Backgrounds need an internet connection',
      'बैकग्राउंड के लिए इंटरनेट ज़रूरी है'
    ],
    'background_download_failed': [
      "Couldn't download that background",
      'यह बैकग्राउंड डाउनलोड नहीं हो सका'
    ],

    // editor — remix gate (Post disabled until the copy is actually changed)
    'remix_change_first': [
      'Make it yours first — change something to post it',
      'पहले कुछ बदलाव करें — तभी पोस्ट कर सकते हैं'
    ],

    // editor — elements & frames
    'elements': ['Elements', 'एलिमेंट्स'],
    'shapes': ['Shapes', 'आकार'],
    'stickers': ['Stickers', 'स्टिकर्स'],
    'drawn_stickers': ['Drawn stickers', 'ड्रॉन स्टिकर्स'],
    'frames': ['Frames', 'फ्रेम'],
    'frame': ['Frame', 'फ्रेम'],
    'width': ['Width', 'चौड़ाई'],
    'frames_simple': ['Simple borders', 'सिंपल बॉर्डर'],
    'frames_fancy': ['Designer frames', 'डिज़ाइनर फ्रेम'],
    'frame_thin': ['Thin', 'पतला'],
    'frame_thick': ['Bold', 'मोटा'],
    'frame_double': ['Double', 'डबल'],
    'frame_dashed': ['Dashed', 'डैश'],
    'frame_rounded': ['Rounded', 'गोल'],
    'frame_corners': ['Corners', 'कॉर्नर'],
    'frame_inset': ['Inset', 'इनसेट'],
    'frame_music': ['Now playing', 'नाउ प्लेइंग'],
    'frame_waveform': ['Waveform', 'वेवफॉर्म'],
    'frame_screen': ['Screen', 'स्क्रीन'],
    'frame_story': ['Story bars', 'स्टोरी बार'],
    'frame_polaroid': ['Polaroid', 'पोलेरॉइड'],
    'frame_film': ['Film strip', 'फिल्म स्ट्रिप'],
    'frame_neon': ['Neon glow', 'नियॉन ग्लो'],
    'frame_tape': ['Tape', 'टेप'],
    'frame_scallop': ['Scallop', 'स्कैलप'],
    'frame_arch': ['Arch', 'आर्च'],
    'frame_ticket': ['Ticket', 'टिकट'],
    'frame_flourish': ['Flourish', 'फ्लोरिश'],
    'frame_dots': ['Beads', 'बीड्स'],
    'frame_vignette': ['Glow edge', 'ग्लो एज'],
    'frame_sparkle': ['Sparkle', 'स्पार्कल'],
    'frame_gradient': ['Gradient ring', 'ग्रेडिएंट रिंग'],

    // editor — quotes sheet / starter
    'tap_quote': ['Tap a quote to add', 'जोड़ने के लिए कोट टैप करें'],
    'double_tap_edit': ['Double tap to edit', 'एडिट के लिए डबल टैप करें'],
  };
}

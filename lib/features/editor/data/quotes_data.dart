import 'package:status_maker/core/localization/strings.dart';

/// Ready-made lines grouped by category. When a user picks a category, the
/// editor offers these so they can create a status without typing a word.
const Map<String, List<String>> kCategoryQuotes = {
  'Good Morning': [
    'Good Morning ☀️',
    'Rise & shine, beautiful soul',
    'New day, new blessings',
    'Every morning is a fresh start',
    'Wishing you a bright & happy day',
    'Wake up. Smile. Conquer.',
    'Good vibes start now',
    'Today is going to be amazing',
    'Sip your coffee & shine ☕',
    'A cup of positivity for you',
    'Mornings are magical',
    'Start your day with a grateful heart',
    'Believe in the beauty of a new day',
    'Sunshine & smiles for you 🌸',
    'Make today ridiculously amazing',
  ],
  'Birthday': [
    'Happy Birthday! 🎂',
    'Another year of you — amazing!',
    'Wishing you joy today & always',
    'Make a wish 🎉',
    'Cheers to you! 🥳',
    'Have the best day ever',
    'Birthday blessings your way',
    'Celebrate YOU today',
    'Older, wiser & more fabulous',
    'May all your dreams come true 🎈',
    'You deserve the whole cake 🍰',
    'Another trip around the sun 🌞',
    'Happiest of birthdays!',
    'Today the world got a little brighter',
    'Party like it’s your birthday!',
  ],
  // Order matches _festivalStyles concepts: Diwali, Holi, Rakhi, Ganesh, Eid,
  // Navratri, Diwali, generic.
  'Festival': [
    'Happy Diwali 🪔',
    'Happy Holi 🌈',
    'Happy Raksha Bandhan',
    'Ganpati Bappa Morya',
    'Eid Mubarak 🌙',
    'Happy Navratri',
    'Shubh Deepavali',
    'Festival of Lights ✨',
    'Rang barse! 🌈',
    'Tied with love',
    'Blessings of Bappa',
    'Blessed Eid',
    'Nine nights of joy 💃',
    'May Lakshmi bless your home',
    'Celebrate with lights & love',
  ],
  'Business': [
    'Dream. Build. Grow.',
    'Success is a mindset',
    'Lead with vision',
    'Hustle & heart',
    'Think big, start small',
    'Your brand, your story',
    'Grow every single day',
    'Turn ideas into impact',
    'Rise & grind',
    'Excellence is a habit',
    'Build your empire',
    'Make it happen',
  ],
  'Motivation': [
    'Believe in yourself',
    'Dream big. Work hard.',
    'You are stronger than you think',
    'One step at a time',
    'Make it happen',
    'Your only limit is you',
    'Stay focused, stay humble',
    'Great things take time',
    'Progress, not perfection',
    'Rise up & grind',
    'Discipline beats motivation',
    'Small steps every day',
    'Be the energy you want to attract',
    'Fall seven times, stand up eight',
    'Success starts with self-belief',
  ],
  'Love': [
    'You are my favorite hello',
    'Forever & always ❤️',
    'You + Me = Home',
    'My heart is yours',
    'Love you to the moon & back 🌙',
    'Every moment with you is a gift',
    'You make my world brighter',
    'Together is my favorite place',
    'You are my today & all my tomorrows',
    'In your arms is where I belong',
    'My favorite love story is ours',
    'You had me at hello',
    'Still falling for you every day',
    'You are my calm & my chaos',
    'Home is wherever you are',
  ],
  // Traditional categories — kept in Hindi in both languages, as these
  // greetings are shared in Devanagari by the audience they're made for.
  'Devotional': _devotionalHi,
  'Good Night': _goodNightHi,
  'Suprabhat': _suprabhatHi,
  'Suvichar': _suvicharHi,
};

// ---- Traditional Hindi line sets (shared by both language maps) -------------
const List<String> _devotionalHi = [
  'राधे राधे 🙏',
  'जय श्री कृष्ण',
  'जय श्री राम 🚩',
  'हर हर महादेव',
  'जय माता दी',
  'ॐ नमः शिवाय',
  'जय हनुमान',
  'गणपति बाप्पा मोरया',
  'भक्ति में ही शक्ति है',
  'प्रभु का आशीर्वाद सदा बना रहे',
  'ॐ शांति शांति शांति',
  'सुबह-श्याम राधे राधे',
];

const List<String> _goodNightHi = [
  'शुभ रात्रि 🌙',
  'मीठे सपने',
  'शुभ रात्रि, प्यारे',
  'तारों भरी रात मुबारक ✨',
  'ईश्वर आपकी रक्षा करे',
  'अच्छे सपने आएँ 🌟',
  'दिन भर की थकान, अब आराम',
  'चैन की नींद सोएँ',
  'कल फिर मिलेंगे',
  'रात की शुभकामनाएँ',
];

const List<String> _suprabhatHi = [
  'सुप्रभात 🌸',
  'शुभ प्रभात 🙏',
  'राम राम जी',
  'आपका दिन मंगलमय हो',
  'ईश्वर आपका दिन शुभ करे',
  'नई सुबह, नई उमंग',
  'चाय के साथ राम राम ☕',
  'सुबह की पहली किरण मुबारक',
  'आज का दिन शुभ हो',
  'प्रभु आपको खुश रखे',
];

const List<String> _suvicharHi = [
  'सुविचार 🌼',
  'जैसी सोच, वैसा जीवन',
  'मेहनत का फल मीठा होता है',
  'सब्र का फल मीठा होता है',
  'अच्छे कर्म ही सच्ची पूँजी हैं',
  'संतोष ही सबसे बड़ा धन है',
  'मुस्कान सबसे सुंदर आभूषण है',
  'समय सबसे बड़ा शिक्षक है',
  'कर्म करो, फल की चिंता मत करो',
  'हर दिन एक नई सीख है',
];

const List<String> kGeneralQuotes = [
  'Live. Laugh. Love.',
  'Good vibes only',
  'Be your own kind of beautiful',
  'Stay positive',
  'Make today count',
  'Enjoy the little things',
  'Keep going',
  'Choose happy',
  'Collect moments, not things',
  'Do more of what makes you happy',
  'Life is beautiful 🌸',
  'Shine bright ✨',
  'Less perfect, more real',
  'Grateful heart, happy life',
  'Create your own sunshine',
];

/// Hindi versions — same categories, same order (Festival matches concepts).
const Map<String, List<String>> kCategoryQuotesHi = {
  'Good Morning': [
    'सुप्रभात ☀️',
    'उठो और चमको',
    'नया दिन, नई शुरुआत',
    'हर सुबह एक नया मौका',
    'आपका दिन शुभ हो',
    'मुस्कुराओ, दिन तुम्हारा है',
    'अच्छी शुरुआत करो',
    'आज कुछ अच्छा होगा',
    'चाय के साथ मुस्कान ☕',
    'सकारात्मकता से भरा दिन',
    'सुबह जादुई होती है',
    'आभार के साथ दिन शुरू करो',
    'नई सुबह की सुंदरता',
    'धूप और मुस्कान 🌸',
    'आज को शानदार बनाओ',
  ],
  'Birthday': [
    'जन्मदिन मुबारक 🎂',
    'एक और शानदार साल',
    'ढेर सारी शुभकामनाएँ',
    'कुछ विश करो 🎉',
    'मुबारक हो! 🥳',
    'सबसे अच्छा दिन हो',
    'जन्मदिन की बधाई',
    'आज का दिन तुम्हारा',
    'हर सपना पूरा हो 🎈',
    'पूरा केक तुम्हारा 🍰',
    'सूरज का एक और चक्कर 🌞',
    'सबसे प्यारा जन्मदिन',
    'आज दुनिया रोशन हुई',
    'खूब मनाओ!',
    'जियो हज़ारों साल',
  ],
  'Festival': [
    'दीपावली की शुभकामनाएँ 🪔',
    'होली मुबारक 🌈',
    'रक्षाबंधन की शुभकामनाएँ',
    'गणपति बाप्पा मोरया',
    'ईद मुबारक 🌙',
    'नवरात्रि की शुभकामनाएँ',
    'शुभ दीपावली',
    'रोशनी का त्योहार ✨',
    'रंग बरसे! 🌈',
    'प्यार के बंधन',
    'बाप्पा का आशीर्वाद',
    'ईद की बधाई',
    'नौ रातों की खुशी 💃',
    'माँ लक्ष्मी का आशीर्वाद',
    'रोशनी और प्यार से मनाओ',
  ],
  'Motivation': [
    'खुद पर भरोसा रखो',
    'बड़े सपने देखो',
    'तुम मजबूत हो',
    'एक कदम, एक बार',
    'कर दिखाओ',
    'तुम्हारी सीमा तुम हो',
    'मेहनत रंग लाती है',
    'सफलता सोच से शुरू',
    'परफेक्ट नहीं, प्रगति',
    'उठो और मेहनत करो',
    'अनुशासन सब कुछ',
    'हर दिन छोटे कदम',
    'सकारात्मक ऊर्जा बनो',
    'गिरो सात बार, उठो आठ',
    'आत्मविश्वास ही सफलता',
  ],
  'Love': [
    'तुम मेरी पहली मुस्कान',
    'हमेशा तुम्हारे साथ ❤️',
    'तुम + मैं = घर',
    'मेरा दिल तुम्हारा',
    'चाँद तक और वापस 🌙',
    'हर पल तुम्हारे साथ ख़ास',
    'तुमसे दुनिया रोशन',
    'साथ रहना सबसे अच्छा',
    'तुम मेरा आज और कल',
    'तुम्हारी बाँहों में सुकून',
    'हमारी कहानी सबसे प्यारी',
    'पहली नज़र का प्यार',
    'अब भी तुम पर फ़िदा',
    'तुम मेरा सुकून हो',
    'जहाँ तुम, वहीं घर',
  ],
  'Devotional': _devotionalHi,
  'Good Night': _goodNightHi,
  'Suprabhat': _suprabhatHi,
  'Suvichar': _suvicharHi,
  'Business': [
    'सपना, मेहनत, तरक्की',
    'सफलता एक सोच है',
    'दूरदृष्टि से नेतृत्व',
    'मेहनत और जुनून',
    'बड़ा सोचो, छोटा शुरू',
    'अपनी पहचान बनाओ',
    'हर दिन बढ़ो',
    'सोच को हकीकत बनाओ',
    'उठो और मेहनत करो',
    'उत्कृष्टता आदत है',
    'अपना साम्राज्य बनाओ',
    'कर दिखाओ',
  ],
};

const List<String> kGeneralQuotesHi = [
  'जियो, हँसो, प्यार करो',
  'अच्छी सोच रखो',
  'खुद पर गर्व करो',
  'सकारात्मक रहो',
  'आज को यादगार बनाओ',
  'छोटी खुशियाँ मनाओ',
  'चलते रहो',
  'खुश रहो',
  'पल संजोओ, चीज़ें नहीं',
  'जो खुश करे वो करो',
  'ज़िंदगी खूबसूरत है 🌸',
  'चमको ✨',
  'कम परफेक्ट, ज़्यादा असली',
  'आभारी दिल, खुश ज़िंदगी',
  'अपनी धूप खुद बनाओ',
];

/// Returns the suggestions for [category] in the current language.
List<String> quotesForCategory(String? category) {
  final map = S.isHi ? kCategoryQuotesHi : kCategoryQuotes;
  final general = S.isHi ? kGeneralQuotesHi : kGeneralQuotes;
  if (category == null) return general;
  final key = category == 'Morning' ? 'Good Morning' : category;
  return map[key] ?? general;
}

/// Builds a large, de-duplicated pool of quotes for [category].
///
/// The selected category's own lines come first (so a specific category is
/// honoured), then the general lines and every other category are appended.
/// This guarantees there are always well over 25 unique quotes to show and to
/// cycle through when the user refreshes. When [category] is null (default),
/// the general lines lead. The result never contains duplicates.
List<String> quotePoolForCategory(String? category) {
  final map = S.isHi ? kCategoryQuotesHi : kCategoryQuotes;
  final general = S.isHi ? kGeneralQuotesHi : kGeneralQuotes;

  final seen = <String>{};
  final pool = <String>[];
  void addAll(List<String> list) {
    for (final q in list) {
      if (seen.add(q)) pool.add(q);
    }
  }

  // Selected category first (if it maps to a real list).
  if (category != null) {
    final key = category == 'Morning' ? 'Good Morning' : category;
    final own = map[key];
    if (own != null) addAll(own);
  }
  // Then general lines, then everything else — plenty to reach 25+.
  addAll(general);
  for (final list in map.values) {
    addAll(list);
  }
  return pool;
}

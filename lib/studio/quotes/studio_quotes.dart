import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/models/quote_model.dart';

// Shorthand constructors keep the table below readable.
QuoteModel _en(String cat, String text, {String? tag}) =>
    QuoteModel(category: cat, language: AppLanguage.en, text: text, tag: tag);
QuoteModel _hi(String cat, String text, {String? tag}) =>
    QuoteModel(category: cat, language: AppLanguage.hi, text: text, tag: tag);

/// Studio quote store: `{category, language, text}` rows, nothing baked into
/// a template. The pre-studio lists in `quotes_data.dart` are merged in by
/// `QuoteRepository`, so this file only needs the lines those lacked —
/// English for the traditionally Hindi-only categories, and the seven new
/// categories in both languages.
final List<QuoteModel> kStudioQuotes = [
  // ---- Good Morning -----------------------------------------------------------
  _en('morning', 'Every sunrise brings a new opportunity.'),
  _en('morning', 'Good morning! Let your light shine today.'),
  _en('morning', 'A new day, a new chance to be grateful.'),
  _en('morning', 'Wake up with purpose and walk with peace.'),
  _en('morning', 'The sun rises for you. Rise for yourself.'),
  _en('morning', 'Soft light, warm tea, and a hopeful heart.'),
  _hi('morning', 'हर सुबह एक नई उम्मीद लेकर आती है।'),
  _hi('morning', 'सुप्रभात! आज का दिन आपके नाम हो।'),
  _hi('morning', 'नई सुबह, नया हौसला, नई शुरुआत।'),
  _hi('morning', 'मुस्कान के साथ दिन की शुरुआत कीजिए।'),
  _hi('morning', 'सूरज की पहली किरण आपके जीवन को रोशन करे।'),
  _hi('morning', 'शुभ प्रभात — ईश्वर आपका दिन मंगलमय करे।'),

  // ---- Good Night -------------------------------------------------------------
  _en('goodnight', 'Good night. Let go of today and rest.'),
  _en('goodnight', 'May your dreams be as gentle as the moonlight.'),
  _en('goodnight', 'The stars are out. Time to rest your heart.'),
  _en('goodnight', 'Sleep well — tomorrow is a fresh page.'),
  _en('goodnight', 'Quiet night, calm mind, grateful soul.'),
  _en('goodnight', 'Rest now. You did enough today.'),
  _hi('goodnight', 'शुभ रात्रि — आज की थकान कल की ताक़त बने।'),
  _hi('goodnight', 'चाँदनी जैसी शीतल नींद आपको मिले।'),
  _hi('goodnight', 'तारों की छाँव में सुकून भरी रात हो।'),
  _hi('goodnight', 'मीठे सपने देखिए, कल एक नया दिन है।'),
  _hi('goodnight', 'शांत रात, शांत मन, शुभ रात्रि।'),

  // ---- Bhakti -----------------------------------------------------------------
  _en('bhakti', 'Jai Shri Ram 🚩'),
  _en('bhakti', 'Radhe Radhe 🙏'),
  _en('bhakti', 'Har Har Mahadev'),
  _en('bhakti', 'With faith in the heart, every path is blessed.'),
  _en('bhakti', 'Om Namah Shivaya'),
  _en('bhakti', 'May the divine light guide your every step.'),
  _hi('bhakti', 'जहाँ श्रद्धा है, वहाँ ईश्वर है।'),
  _hi('bhakti', 'प्रभु की कृपा सदा आप पर बनी रहे।'),
  _hi('bhakti', 'भक्ति में ही सच्ची शांति है।'),
  _hi('bhakti', 'हर हर महादेव — शिव ही सत्य है।'),
  _hi('bhakti', 'राधे राधे — प्रेम ही पूजा है।'),

  // ---- Motivation -------------------------------------------------------------
  _en('motivation', 'Discipline today, freedom tomorrow.'),
  _en('motivation', 'Your comfort zone is not your home.'),
  _en('motivation', 'Work in silence. Let results speak.'),
  _en('motivation', 'Start where you are. Use what you have.'),
  _hi('motivation', 'संघर्ष जितना बड़ा, जीत उतनी शानदार।'),
  _hi('motivation', 'रुकना नहीं है — मंज़िल सामने है।'),
  _hi('motivation', 'आज का अनुशासन, कल की आज़ादी।'),
  _hi('motivation', 'खुद पर भरोसा ही पहली जीत है।'),

  // ---- Success ----------------------------------------------------------------
  _en('success', 'Success is built one quiet morning at a time.'),
  _en('success', 'Dream it. Plan it. Do it.'),
  _en('success', 'Stay humble. Work hard. Be kind.'),
  _en('success', 'Big goals, small steps, every single day.'),
  _en('success', 'The grind is quiet. The results are loud.'),
  _en('success', 'Earned, not given.'),
  _en('success', 'Winners focus on winning, not on the noise.'),
  _en('success', 'Keep building. The view gets better.'),
  _hi('success', 'सफलता शोर नहीं करती, दिखाई देती है।'),
  _hi('success', 'मेहनत का कोई शॉर्टकट नहीं होता।'),
  _hi('success', 'सपने देखो, योजना बनाओ, कर दिखाओ।'),
  _hi('success', 'हर दिन एक कदम — यही सफलता का रास्ता है।'),
  _hi('success', 'विनम्र रहो, मेहनत करो, आगे बढ़ो।'),
  _hi('success', 'जो कमाया है, वही असली है।'),
  _hi('success', 'धैर्य और मेहनत — सफलता के दो पंख।'),
  _hi('success', 'मंज़िल उन्हीं को मिलती है जो चलते रहते हैं।'),

  // ---- Business ---------------------------------------------------------------
  _en('business', 'Quality is the best business plan.'),
  _en('business', 'Trusted service. Honest prices. Every time.'),
  _en('business', 'Your success is our business.'),
  _en('business', 'Thank you for choosing us.'),
  _hi('business', 'भरोसा ही हमारी पहचान है।'),
  _hi('business', 'गुणवत्ता से समझौता नहीं।'),
  _hi('business', 'आपका विश्वास, हमारी ज़िम्मेदारी।'),
  _hi('business', 'हमें चुनने के लिए धन्यवाद।'),

  // ---- Birthday ---------------------------------------------------------------
  _en('birthday', 'Happy Birthday! May this year be your best yet.'),
  _en('birthday', 'Cake, candles and a whole lot of love.'),
  _en('birthday', 'Wishing you a year as wonderful as you are.'),
  _hi('birthday', 'जन्मदिन की ढेर सारी शुभकामनाएँ!'),
  _hi('birthday', 'आपका हर सपना इस साल पूरा हो।'),
  _hi('birthday', 'खुशियों से भरा हो आपका हर दिन।'),

  // ---- Festival (tagged per occasion) -----------------------------------------
  _en('festival', 'Happy Diwali! May light win over darkness.', tag: 'diwali'),
  _en('festival', 'Wishing you a Diwali full of joy and prosperity.', tag: 'diwali'),
  _en('festival', 'May Lakshmi bless your home this Diwali.', tag: 'diwali'),
  _hi('festival', 'दीपावली की हार्दिक शुभकामनाएँ 🪔', tag: 'diwali'),
  _hi('festival', 'दीपों का यह पर्व आपके जीवन में खुशियाँ लाए।', tag: 'diwali'),
  _hi('festival', 'माँ लक्ष्मी की कृपा आप पर बनी रहे।', tag: 'diwali'),

  _en('festival', 'Happy Holi! Let colours of joy fill your life.', tag: 'holi'),
  _en('festival', 'Bura na mano, Holi hai! 🌈', tag: 'holi'),
  _hi('festival', 'होली की रंगभरी शुभकामनाएँ 🌈', tag: 'holi'),
  _hi('festival', 'रंगों का त्योहार आपके जीवन में खुशियाँ भर दे।', tag: 'holi'),
  _hi('festival', 'बुरा न मानो, होली है!', tag: 'holi'),

  _en('festival', 'Happy Raksha Bandhan — a bond beyond words.', tag: 'rakhi'),
  _en('festival', 'A thread of love, a promise for life.', tag: 'rakhi'),
  _hi('festival', 'रक्षाबंधन की हार्दिक शुभकामनाएँ', tag: 'rakhi'),
  _hi('festival', 'भाई-बहन का यह बंधन सदा अटूट रहे।', tag: 'rakhi'),
  _hi('festival', 'एक धागा, एक वादा, उम्र भर का साथ।', tag: 'rakhi'),

  _en('festival', 'Happy Independence Day 🇮🇳', tag: 'independence'),
  _en('festival', 'Proud to be Indian. Jai Hind!', tag: 'independence'),
  _hi('festival', 'स्वतंत्रता दिवस की हार्दिक शुभकामनाएँ 🇮🇳', tag: 'independence'),
  _hi('festival', 'जय हिंद! वंदे मातरम्!', tag: 'independence'),
  _hi('festival', 'आज़ादी का यह पर्व हमें एकता सिखाए।', tag: 'independence'),

  _en('festival', 'Ganpati Bappa Morya! 🙏', tag: 'ganesh'),
  _en('festival', 'May Bappa remove every obstacle from your path.', tag: 'ganesh'),
  _hi('festival', 'गणपति बाप्पा मोरया!', tag: 'ganesh'),
  _hi('festival', 'बाप्पा आपके जीवन के सारे विघ्न दूर करें।', tag: 'ganesh'),

  _en('festival', 'Eid Mubarak 🌙', tag: 'eid'),
  _en('festival', 'May this Eid bring peace and blessings.', tag: 'eid'),
  _hi('festival', 'ईद मुबारक 🌙', tag: 'eid'),
  _hi('festival', 'यह ईद आपके जीवन में खुशियाँ और बरकत लाए।', tag: 'eid'),

  _en('festival', 'Happy Navratri — nine nights of devotion.', tag: 'navratri'),
  _en('festival', 'May Maa Durga bless you with strength.', tag: 'navratri'),
  _hi('festival', 'नवरात्रि की हार्दिक शुभकामनाएँ', tag: 'navratri'),
  _hi('festival', 'माँ दुर्गा आपको शक्ति और सुख प्रदान करें।', tag: 'navratri'),

  // ---- Love -------------------------------------------------------------------
  _en('love', 'With you, every ordinary day feels like magic.'),
  _en('love', 'You are my favourite place to be.'),
  _en('love', 'Some hearts just understand each other.'),
  _hi('love', 'तुम्हारे साथ हर पल ख़ास है।'),
  _hi('love', 'तुम मेरी हर दुआ का जवाब हो।'),
  _hi('love', 'प्यार वही जो हर हाल में साथ निभाए।'),

  // ---- Heartbreak -------------------------------------------------------------
  _en('heartbreak', 'Some goodbyes teach what hellos never could.'),
  _en('heartbreak', 'I healed quietly, the way I loved you.'),
  _en('heartbreak', 'Not every ending is a loss.'),
  _en('heartbreak', 'The rain knows how I feel tonight.'),
  _en('heartbreak', 'I let go, but I never forgot.'),
  _en('heartbreak', 'Broken, but still beautiful.'),
  _en('heartbreak', 'Silence says what I could not.'),
  _hi('heartbreak', 'कुछ रिश्ते अधूरे रहकर भी पूरे लगते हैं।'),
  _hi('heartbreak', 'दर्द ने सिखाया, जो तुमने नहीं सिखाया।'),
  _hi('heartbreak', 'ख़ामोशी भी बहुत कुछ कह जाती है।'),
  _hi('heartbreak', 'टूटकर भी मुस्कुराना सीख लिया है।'),
  _hi('heartbreak', 'तुम चले गए, यादें रह गईं।'),
  _hi('heartbreak', 'हर बिछड़ना हार नहीं होता।'),
  _hi('heartbreak', 'दिल अब भी तुम्हारा नाम लेता है, बस चुपके से।'),

  // ---- Friendship -------------------------------------------------------------
  _en('friendship', 'Good friends make the hard days lighter.'),
  _en('friendship', 'Friends are the family we choose.'),
  _en('friendship', 'Here\'s to the ones who stayed.'),
  _en('friendship', 'Same jokes, same chai, same old friends.'),
  _en('friendship', 'Distance means nothing when someone means everything.'),
  _en('friendship', 'Happy Friendship Day, my people.'),
  _en('friendship', 'A true friend is a treasure.'),
  _hi('friendship', 'सच्चा दोस्त ज़िंदगी का सबसे बड़ा तोहफ़ा है।'),
  _hi('friendship', 'दोस्ती — बिना शर्त, बिना मतलब।'),
  _hi('friendship', 'यारों के बिना ज़िंदगी अधूरी है।'),
  _hi('friendship', 'वही चाय, वही बातें, वही पुराने यार।'),
  _hi('friendship', 'दोस्ती का रिश्ता खून से नहीं, दिल से बनता है।'),
  _hi('friendship', 'फ्रेंडशिप डे मुबारक, मेरे यारो!'),
  _hi('friendship', 'दूरियाँ मायने नहीं रखतीं, जब दोस्त अपना हो।'),

  // ---- Wishes -----------------------------------------------------------------
  _en('wishes', 'Congratulations! You earned every bit of this.'),
  _en('wishes', 'Happy Anniversary — here\'s to forever.'),
  _en('wishes', 'Thank you for everything you do.'),
  _en('wishes', 'Wishing you health, happiness and peace.'),
  _en('wishes', 'Best wishes on your new beginning.'),
  _en('wishes', 'Get well soon — we miss your smile.'),
  _en('wishes', 'Happy New Year! A fresh start for all of us.'),
  _en('wishes', 'Welcome to the family, little one.'),
  _hi('wishes', 'बहुत-बहुत बधाई हो! आप इसके हक़दार हैं।'),
  _hi('wishes', 'सालगिरह मुबारक — यह साथ सदा बना रहे।'),
  _hi('wishes', 'आपके साथ और सहयोग के लिए धन्यवाद।'),
  _hi('wishes', 'स्वस्थ रहें, खुश रहें, आगे बढ़ते रहें।'),
  _hi('wishes', 'नई शुरुआत की ढेर सारी शुभकामनाएँ।'),
  _hi('wishes', 'जल्दी स्वस्थ हो जाइए — आपकी मुस्कान की कमी है।'),
  _hi('wishes', 'नववर्ष की हार्दिक शुभकामनाएँ!'),
  _hi('wishes', 'नन्हे मेहमान का स्वागत है।'),

  // ---- Nature -----------------------------------------------------------------
  _en('nature', 'Nature does not hurry, yet everything blooms.'),
  _en('nature', 'The earth has music for those who listen.'),
  _en('nature', 'Breathe in the forest. Let it slow you down.'),
  _en('nature', 'Rivers know: there is no hurry.'),
  _en('nature', 'Look deep into nature and you will understand.'),
  _en('nature', 'Green is the colour of peace.'),
  _en('nature', 'Mountains teach patience.'),
  _hi('nature', 'प्रकृति जल्दी नहीं करती, फिर भी सब कुछ खिलता है।'),
  _hi('nature', 'पेड़ों की छाँव में सुकून है।'),
  _hi('nature', 'नदी की तरह बहते रहो, ठहरो मत।'),
  _hi('nature', 'हरियाली ही असली समृद्धि है।'),
  _hi('nature', 'पहाड़ धैर्य सिखाते हैं।'),
  _hi('nature', 'प्रकृति से जुड़ो, खुद से जुड़ो।'),
  _hi('nature', 'धरती के पास हर सवाल का जवाब है।'),

  // ---- Minimal ----------------------------------------------------------------
  _en('minimal', 'Less, but better.'),
  _en('minimal', 'Breathe. Begin again.'),
  _en('minimal', 'Simplicity is the final sophistication.'),
  _en('minimal', 'Quiet mind, clear path.'),
  _en('minimal', 'Make room for what matters.'),
  _en('minimal', 'Slow is smooth. Smooth is fast.'),
  _en('minimal', 'Stay soft. Stay strong.'),
  _hi('minimal', 'कम, पर बेहतर।'),
  _hi('minimal', 'सरलता ही सुंदरता है।'),
  _hi('minimal', 'शांत मन, साफ़ रास्ता।'),
  _hi('minimal', 'साँस लो, फिर से शुरू करो।'),
  _hi('minimal', 'जो ज़रूरी है, उसके लिए जगह बनाओ।'),
  _hi('minimal', 'धीरे चलो, पर रुको मत।'),
  _hi('minimal', 'कोमल रहो, मज़बूत रहो।'),

  // ---- Premium Dark -----------------------------------------------------------
  _en('premium_dark', 'Elegance is refusal.'),
  _en('premium_dark', 'Built different. Stay rare.'),
  _en('premium_dark', 'Luxury is attention to detail.'),
  _en('premium_dark', 'Be so good they can\'t ignore you.'),
  _en('premium_dark', 'Classic never goes out of style.'),
  _en('premium_dark', 'Quiet confidence. Loud results.'),
  _en('premium_dark', 'Power is calm.'),
  _hi('premium_dark', 'शालीनता ही असली शान है।'),
  _hi('premium_dark', 'अलग बनो, ख़ास रहो।'),
  _hi('premium_dark', 'हर छोटी बात पर ध्यान — यही विलासिता है।'),
  _hi('premium_dark', 'इतने अच्छे बनो कि नज़रअंदाज़ न किया जा सके।'),
  _hi('premium_dark', 'शांत आत्मविश्वास, बुलंद नतीजे।'),
  _hi('premium_dark', 'क्लासिक कभी पुराना नहीं होता।'),
  _hi('premium_dark', 'ताक़त शांत होती है।'),
];

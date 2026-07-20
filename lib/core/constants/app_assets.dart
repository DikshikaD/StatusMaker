class AppAssets {
  static const String placeholderImage = 'https://picsum.photos/800/1200';
  static const String logo = 'assets/images/logo.png'; // Example

  // ---------------------------------------------------------------------------
  // Background category images (bundled assets).
  // Grouped by category so the editor can show them under labelled sections.
  // ---------------------------------------------------------------------------
  static const String _morningDir = 'assets/categories/morning';
  static const String _festivalDir = 'assets/categories/festival';
  static const String _loveDir = 'assets/categories/love';
  static const String _birthdayDir = 'assets/categories/birthday';

  static const List<String> morningBackgrounds = [
    '$_morningDir/morning_1.jpg',
    '$_morningDir/morning_2.jpg',
    '$_morningDir/morning_3.jpg',
    '$_morningDir/morning_4.jpg',
    '$_morningDir/morning_5.jpg',
  ];

  static const List<String> festivalBackgrounds = [
    '$_festivalDir/fest_1.png',
    '$_festivalDir/fest_2.png',
    '$_festivalDir/fest_3.png',
    '$_festivalDir/fest_4.png',
    '$_festivalDir/fest_5.png',
  ];

  static const List<String> loveBackgrounds = [
    '$_loveDir/love_1.png',
    '$_loveDir/love_2.png',
    '$_loveDir/love_3.png',
    '$_loveDir/love_4.png',
    '$_loveDir/love_5.png',
  ];

  static const List<String> birthdayBackgrounds = [
    '$_birthdayDir/birthday_1.png',
    '$_birthdayDir/birthday_2.png',
    '$_birthdayDir/birthday_3.png',
    '$_birthdayDir/birthday_4.png',
    '$_birthdayDir/birthday_5.png',
    '$_birthdayDir/birthday_6.png',
  ];
}

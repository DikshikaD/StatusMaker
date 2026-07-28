import 'package:flutter/foundation.dart';

/// Where a finished action wants to send the user, and whether the Favorites
/// tab should land on "My Creations".
///
/// Deliberately NOT const-constructible and without an `==` override: each
/// request must be a distinct object so a [ValueNotifier] always notifies, even
/// when the user saves twice in a row and the destination is identical.
class TabRequest {
  final int index;
  final bool showCreations;

  TabRequest(this.index, {this.showCreations = false});
}

/// App-level navigation signals.
///
/// The editors are pushed on top of [MainLayout], sometimes several routes deep
/// (Create → theme → category → editor), so "finish and go to My Creations"
/// can't be expressed by popping a known number of routes or by threading a
/// result back through every screen in between. Instead the editor states its
/// intent here and the shell acts on it: it pops everything above itself and
/// switches tabs.
class AppNav {
  AppNav._();

  /// Bottom-nav indices, matching MainLayout's item order.
  static const int homeTab = 0;
  static const int favoritesTab = 3;

  /// Name given to MainLayout's route so the shell can pop back to exactly
  /// itself rather than relying on it happening to be the first route.
  static const String shellRouteName = '/main';

  /// Listened to by MainLayout. Null until something asks to move.
  static final ValueNotifier<TabRequest?> request =
      ValueNotifier<TabRequest?>(null);

  /// After saving privately: show the user their new creation.
  static void goToMyCreations() =>
      request.value = TabRequest(favoritesTab, showCreations: true);

  /// After posting publicly: show the feed the post went to.
  static void goToHome() => request.value = TabRequest(homeTab);
}

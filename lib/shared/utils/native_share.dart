import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Where the editor's share sheet can send a finished status.
enum ShareTarget {
  whatsapp('whatsapp'),
  instagram('instagram'),
  facebook('facebook'),

  /// The plain system chooser — every other app the device offers.
  more('more');

  const ShareTarget(this.id);

  /// Matches the keys in MainActivity.TARGET_PACKAGES on the Android side.
  final String id;
}

/// Targeted image sharing.
///
/// `share_plus` can only open the generic OS chooser, so handing the PNG
/// straight to a named app goes through a small MethodChannel implemented in
/// `MainActivity.kt` (ACTION_SEND with the destination package set). That is
/// Android-only: on iOS — and any time the channel or the target app isn't
/// there — we fall back to the system share sheet, which still gets the job
/// done in two taps instead of one.
class NativeShare {
  NativeShare._();

  static const MethodChannel _channel =
      MethodChannel('status_maker/native_share');

  static const Set<ShareTarget> _branded = {
    ShareTarget.whatsapp,
    ShareTarget.instagram,
    ShareTarget.facebook,
  };

  /// Cached because the answer only changes if the user installs an app while
  /// the editor is open, and the sheet asks on every open.
  static Set<ShareTarget>? _installed;

  /// Which branded targets have an app installed, so the sheet can dim the ones
  /// that would only bounce to the system chooser.
  ///
  /// Returns all of them when we can't tell (iOS, or the channel is missing) —
  /// dimming everything would look broken, and tapping still works.
  static Future<Set<ShareTarget>> installedTargets() async {
    if (_installed != null) return _installed!;
    if (!Platform.isAndroid) return _installed = _branded;
    try {
      final ids = await _channel.invokeListMethod<String>('installedTargets');
      if (ids == null) return _installed = _branded;
      return _installed = _branded.where((t) => ids.contains(t.id)).toSet();
    } catch (e) {
      debugPrint('NativeShare.installedTargets failed: $e');
      return _installed = _branded;
    }
  }

  /// Sends the PNG at [path] to [target].
  ///
  /// Returns true when the target app took it, false when we fell back to the
  /// system chooser (so the caller can explain why, if it wants to).
  static Future<bool> shareImage({
    required String path,
    required ShareTarget target,
    String? text,
  }) async {
    if (target != ShareTarget.more && Platform.isAndroid) {
      try {
        final ok = await _channel.invokeMethod<bool>('shareImage', {
          'path': path,
          'target': target.id,
          'text': text,
        });
        if (ok == true) return true;
      } catch (e) {
        debugPrint('NativeShare.shareImage(${target.id}) failed: $e');
      }
    }
    await Share.shareXFiles([XFile(path)], text: text);
    return target == ShareTarget.more;
  }
}

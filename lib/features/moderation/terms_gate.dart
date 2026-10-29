import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:status_maker/core/constants/legal_urls.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Play's user-generated-content policy: before someone can publish to the
/// public feed they must agree to terms that forbid objectionable content.
/// Asked once, on the first Post; the answer is remembered on this device.
class TermsGate {
  TermsGate._();

  static const _prefKey = 'ugc_terms_accepted_v1';
  static bool? _accepted;

  /// True when the user has agreed (now or earlier). False means they backed
  /// out, and the caller must not publish.
  static Future<bool> ensureAccepted(BuildContext context) async {
    if (_accepted ?? await _read()) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => const _TermsDialog(),
        ) ??
        false;
    if (ok) {
      _accepted = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKey, true);
      } catch (_) {
        // Remembered for this session even if it can't be persisted.
      }
    }
    return ok;
  }

  static Future<bool> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _accepted = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}

class _TermsDialog extends StatelessWidget {
  const _TermsDialog();

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: 14.sp, color: AppColors.textSecondary);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        S.t('terms_gate_title'),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text.rich(
        TextSpan(
          style: body,
          children: [
            TextSpan(text: S.t('terms_gate_body')),
            const TextSpan(text: '\n\n'),
            TextSpan(
              text: S.t('terms_conditions'),
              style: body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(Uri.parse(LegalUrls.terms),
                    mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.t('cancel'),
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(S.t('terms_gate_agree')),
        ),
      ],
    );
  }
}

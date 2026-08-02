import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';

/// One-off tool for seeding the public Home feed with the bundled fixed
/// templates, so a fresh install isn't looking at an empty feed.
///
/// **Debug builds only** — [open] refuses to push this in release, and nothing
/// links to it from the normal UI. It publishes real, public rows.
///
/// It deliberately goes through the app's own publish pipeline rather than
/// inserting rows directly:
///
///   FixedTemplateCanvas -> captureCanvas -> StatusRepository.saveDesign
///
/// so every seeded row is shaped exactly like one a user creates with Post —
/// same editable `design` jsonb, same thumbnail bucket, same portable image
/// rewriting. That's what makes them customizable by everyone else: tapping
/// Customize on a seeded card runs the identical code path as remixing any
/// other status.
///
/// Two details that matter for correctness:
///  * The thumbnail is rendered from [FixedTemplate.previewDesign] — the same
///    snapshot the Ready Templates cards show — so the feed image matches the
///    design people already recognise.
///  * The stored design uses `includeHiddenPhoto: true`, matching what tapping
///    a ready template does today, so a remixer gets the photo frame to tap.
///    Its `canvasSize` is [kFixedCanvasSize], which the editor maps onto
///    whatever canvas the opening device has — so the layout survives being
///    opened on a different phone.
class SeedFeedScreen extends StatefulWidget {
  const SeedFeedScreen({super.key});

  /// Debug-only entry point. No-op in release.
  static Future<void> open(BuildContext context) async {
    if (!kDebugMode) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SeedFeedScreen()),
    );
  }

  @override
  State<SeedFeedScreen> createState() => _SeedFeedScreenState();
}

enum _ItemState { pending, working, done, failed }

class _Row {
  final FixedTemplate template;
  _ItemState state = _ItemState.pending;
  String? error;
  bool selected = true;
  _Row(this.template);
}

class _SeedFeedScreenState extends State<SeedFeedScreen> {
  final _repo = StatusRepository();
  final _canvasKey = GlobalKey();

  late final List<_Row> _rows =
      kFixedTemplates.map((t) => _Row(t)).toList(growable: false);

  /// The template currently mounted in the offscreen-ish canvas below. Only one
  /// is rendered at a time — capture needs a laid-out RepaintBoundary, so the
  /// canvas has to actually be in the tree.
  FixedTemplate? _rendering;

  bool _running = false;
  bool _cancelled = false;

  int get _doneCount => _rows.where((r) => r.state == _ItemState.done).length;
  int get _failedCount =>
      _rows.where((r) => r.state == _ItemState.failed).length;

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _cancelled = false;
    });

    for (final row in _rows) {
      if (_cancelled) break;
      if (!row.selected || row.state == _ItemState.done) continue;

      setState(() {
        row.state = _ItemState.working;
        row.error = null;
        _rendering = row.template;
      });

      try {
        // Let the canvas mount and lay out. Two frames, matching
        // StatusPersonalizerScreen._capture — one isn't always enough, the
        // first can be the frame already in flight.
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || _cancelled) break;

        final bytes = await captureCanvas(_canvasKey);
        if (bytes == null) {
          throw StateError('canvas capture returned no bytes');
        }
        if (!mounted || _cancelled) break;

        await _repo.saveDesign(
          design: row.template.design(includeHiddenPhoto: true),
          thumbnailBytes: bytes,
          title: row.template.name,
          category: row.template.quoteCategory,
          makePublic: true,
        );

        if (!mounted) return;
        setState(() => row.state = _ItemState.done);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          row.state = _ItemState.failed;
          row.error = e.toString();
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _rendering = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _rows.where((r) => r.selected).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seed public feed'),
        actions: [
          if (_running)
            TextButton(
              onPressed: () => setState(() => _cancelled = true),
              child: const Text('Stop'),
            ),
        ],
      ),
      body: Column(
        children: [
          _banner(selected),
          // The live canvas being captured. Kept small and on-screen because a
          // RepaintBoundary must be laid out and painted to be capturable —
          // an Offstage subtree never paints, so toImage() would fail.
          SizedBox(
            height: 160.h,
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: _rendering == null
                      ? ColoredBox(color: AppColors.cardLight)
                      : FixedTemplateCanvas(
                          design: _rendering!.previewDesign(),
                          lineLimits: _rendering!.lineLimits,
                        ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _list()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          child: ElevatedButton(
            onPressed: _running || selected == 0 ? null : _run,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            child: Text(
              _running
                  ? 'Publishing… $_doneCount/$selected'
                  : 'Publish $selected template${selected == 1 ? '' : 's'}',
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(int selected) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.12),
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      child: Text(
        'Publishes PUBLIC rows to the live backend, owned by this device\'s '
        'anonymous account. Running twice creates duplicates — deselect what '
        'is already seeded.\n'
        'Done: $_doneCount   Failed: $_failedCount',
        style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        return CheckboxListTile(
          dense: true,
          value: row.selected,
          onChanged: _running
              ? null
              : (v) => setState(() => row.selected = v ?? false),
          title: Text(
            row.template.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            row.error ??
                '${row.template.theme} · ${row.template.quoteCategory}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: row.state == _ItemState.failed
                  ? Colors.redAccent
                  : AppColors.textSecondary,
            ),
          ),
          secondary: _stateIcon(row.state),
        );
      },
    );
  }

  Widget _stateIcon(_ItemState s) => switch (s) {
        _ItemState.pending =>
          Icon(Icons.circle_outlined, color: AppColors.textSecondary, size: 20.w),
        _ItemState.working => SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        _ItemState.done =>
          Icon(Icons.check_circle, color: Colors.green, size: 20.w),
        _ItemState.failed =>
          Icon(Icons.error, color: Colors.redAccent, size: 20.w),
      };
}

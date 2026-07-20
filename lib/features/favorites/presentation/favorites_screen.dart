import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/shared/widgets/empty_state.dart';
import 'package:status_maker/core/utils/responsive.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(S.t('favorites_title')),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle:
                TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            tabs: [
              Tab(text: S.t('saved_templates')),
              Tab(text: S.t('my_creations')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EmptyState(
              icon: Icons.bookmark_border,
              title: S.t('fav_empty_title'),
              message: S.t('fav_empty_msg'),
            ),
            EmptyState(
              icon: Icons.brush_outlined,
              title: S.t('creations_empty_title'),
              message: S.t('creations_empty_msg'),
            ),
          ],
        ),
      ),
    );
  }
}

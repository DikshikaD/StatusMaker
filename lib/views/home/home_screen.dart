import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: SafeArea(
        bottom: false,
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                // Compact Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(4), vertical: context.hp(1)),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.wp(2)),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(context.wp(2.5)),
                        ),
                        child: Icon(CupertinoIcons.square_stack_3d_up_fill, color: Colors.white, size: context.sp(18)),
                      ),
                      SizedBox(width: context.wp(3)),
                      Text(
                        'StatusMaker',
                        style: TextStyle(
                          fontSize: context.sp(18),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(CupertinoIcons.search, size: context.sp(22)),
                        color: AppColors.textPrimary,
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(width: context.wp(4)),
                      IconButton(
                        icon: Icon(CupertinoIcons.bell, size: context.sp(22)),
                        color: AppColors.textPrimary,
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: context.hp(1)),
                
                // Compact Categories Pill List
                SizedBox(
                  height: context.hp(14), // Increased height for story-style chips
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: viewModel.categories.length,
                    itemBuilder: (context, index) {
                      final categoryMap = viewModel.categories[index];
                      return CategoryChip(
                        label: categoryMap['name']!,
                        imageUrl: categoryMap['image']!,
                        isSelected: viewModel.selectedCategory == categoryMap['name'],
                        onTap: () => viewModel.selectCategory(categoryMap['name']!),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: context.hp(1.5)),
                
                // Single Column ListView Feed
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: context.wp(4),
                      right: context.wp(4),
                      bottom: context.hp(12), // Space for bottom nav
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: viewModel.statuses.length,
                    itemBuilder: (context, index) {
                      return StatusCard(status: viewModel.statuses[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

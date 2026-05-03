import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: context.hp(10), // ~80px on typical screens
        title: Padding(
          padding: EdgeInsets.only(left: context.wp(2), top: context.hp(1.2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GradientText(
                'Status Maker',
                gradient: AppColors.primaryGradient,
                style: TextStyle(
                  fontSize: context.sp(26),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.hp(0.5)),
              Text(
                'Find your perfect vibe',
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: context.wp(5), top: context.hp(1.2)),
            decoration: BoxDecoration(
              color: AppColors.primaryGradientStart.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.bell,
                color: AppColors.primaryGradientStart,
                size: context.sp(24),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: context.hp(2.5)), 
                  // Categories
                  Container(
                    height: context.hp(15.5), // ~130px
                    padding: EdgeInsets.symmetric(vertical: context.hp(0.6)),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: context.wp(5)),
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.categories.length,
                      itemBuilder: (context, index) {
                        final categoryMap = viewModel.categories[index];
                        final categoryName = categoryMap['name']!;
                        final categoryImage = categoryMap['image']!;
                        
                        return CategoryChip(
                          label: categoryName,
                          imageUrl: categoryImage,
                          isSelected: viewModel.selectedCategory == categoryName,
                          onTap: () => viewModel.selectCategory(categoryName),
                        );
                      },
                    ),
                  ),
                    
                  // Feed
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        left: context.wp(5),
                        right: context.wp(5),
                        top: context.hp(1.2),
                        bottom: context.hp(12), // Space for BottomNav
                      ),
                      itemCount: viewModel.statuses.length,
                      itemBuilder: (context, index) {
                        return StatusCard(status: viewModel.statuses[index]);
                      },
                    ),
                  ),
                ],
              ),
              
              // Floating "+" Button matching the design
              Positioned(
                right: context.wp(6),
                bottom: context.hp(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGradientStart.withOpacity(0.4),
                        blurRadius: context.wp(4),
                        offset: Offset(0, context.hp(0.6)),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white,
                      width: context.wp(0.8),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: context.sp(28),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

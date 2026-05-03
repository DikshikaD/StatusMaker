import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const GradientText(
            'Status',
            gradient: AppColors.primaryGradient,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                CupertinoIcons.bell,
                color: AppColors.primaryGradientStart,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    // Categories
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: viewModel.categories.length,
                        itemBuilder: (context, index) {
                          final category = viewModel.categories[index];
                          return CategoryChip(
                            label: category,
                            isSelected: viewModel.selectedCategory == category,
                            onTap: () => viewModel.selectCategory(category),
                          );
                        },
                      ),
                    ),
                    
                    // Feed
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 10,
                          bottom: 100, // Space for BottomNav
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
                  right: 24,
                  bottom: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
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

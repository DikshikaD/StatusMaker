import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/models/status_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';

class StatusCard extends StatelessWidget {
  final StatusModel status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.hp(3)), // ~24px
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(6)), // ~24px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: context.wp(2.5),
            offset: Offset(0, context.hp(0.6)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.wp(6)),
        child: Stack(
          children: [
            // Background Image
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.network(
                status.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: context.wp(5),
              right: context.wp(5),
              bottom: context.hp(2.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.text,
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: context.sp(20),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: context.hp(2.5)), // ~20px
                  
                  // Action Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.wp(1.5), vertical: context.hp(0.7)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(context.wp(8)), // ~30px
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Share Button
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.wp(4), vertical: context.hp(1)),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(context.wp(6)), // ~24px
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.share, 
                                  color: Colors.white, size: context.sp(16)),
                              SizedBox(width: context.wp(1.5)),
                              Text(
                                'Share',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: context.sp(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.wp(2)),
                        
                        // Edit Button
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.wp(4), vertical: context.hp(1)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(context.wp(6)), // ~24px
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: context.sp(14),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Like Button
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            CupertinoIcons.heart,
                            color: Colors.white,
                            size: context.sp(24),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: context.wp(2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

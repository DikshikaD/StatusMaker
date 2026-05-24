import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../data/models/status_model.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_colors.dart';

class StatusCard extends StatelessWidget {
  final StatusModel status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.hp(3)), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(6)),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.wp(6)),
        child: AspectRatio(
          aspectRatio: 1, 
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                status.imageUrl,
                fit: BoxFit.cover,
              ),
              
              // Bottom Gradient for Text/Actions
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.4, 0.6, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // Quote Watermark
              Positioned(
                left: context.wp(4),
                bottom: context.hp(13),
                child: Icon(
                  CupertinoIcons.quote_bubble_fill,
                  color: Colors.white.withOpacity(0.15),
                  size: context.wp(25),
                ),
              ),

              // Content & Actions
              Positioned(
                left: context.wp(4),
                right: context.wp(4),
                bottom: context.hp(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Text
                    Text(
                      status.text,
                      maxLines: 4, // Allow more lines since header is gone
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.sp(18), // Slightly bigger
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.hp(3)),
                    
                    // Action Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Primary Action (Copy Text)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.wp(5), vertical: context.hp(1)),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(context.wp(6)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGradientStart.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.doc_on_doc_fill, color: Colors.white, size: context.sp(18)),
                              SizedBox(width: context.wp(1.5)),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: context.sp(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Secondary Actions (Save & Share)
                        Row(
                          children: [
                            // Download
                            ClipRRect(
                              borderRadius: BorderRadius.circular(context.wp(6)),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(context.wp(2.5)),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Icon(CupertinoIcons.cloud_download, color: Colors.white, size: context.sp(18)),
                                ),
                              ),
                            ),
                            SizedBox(width: context.wp(2.5)),
                            // Share
                            ClipRRect(
                              borderRadius: BorderRadius.circular(context.wp(6)),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(context.wp(2.5)),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: context.sp(18)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

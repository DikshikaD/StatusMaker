import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../data/models/status_model.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_colors.dart';

class StatusCard extends StatelessWidget {
  final StatusModel status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.hp(2.5)), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(5)),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientStart.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.wp(5)),
        child: AspectRatio(
          aspectRatio: 1, // Square card for a balanced ListView appearance
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                status.imageUrl,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.4, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: context.wp(4),
                right: context.wp(4),
                bottom: context.hp(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: context.hp(1.5)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: context.wp(3), vertical: context.hp(0.8)),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(context.wp(4)),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.heart_fill, color: Colors.white, size: context.sp(14)),
                              SizedBox(width: context.wp(1.5)),
                              Text('1.2k', style: TextStyle(color: Colors.white, fontSize: context.sp(11), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        SizedBox(width: context.wp(2)),
                        Container(
                          padding: EdgeInsets.all(context.wp(2)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.share, color: Colors.white, size: context.sp(14)),
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

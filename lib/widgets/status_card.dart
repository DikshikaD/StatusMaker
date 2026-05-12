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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.4, 0.6, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: context.wp(4),
                right: context.wp(4),
                bottom: context.hp(2.5),
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
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.hp(2)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(context.wp(4)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: context.wp(5), vertical: context.hp(1.5)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(context.wp(4)),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionButton(
                                context,
                                icon: CupertinoIcons.heart_fill,
                                label: '1.2k',
                                color: Colors.redAccent,
                              ),
                              _buildActionButton(
                                context,
                                icon: CupertinoIcons.cloud_download,
                                label: 'Save',
                                color: Colors.white,
                              ),
                              _buildActionButton(
                                context,
                                icon: CupertinoIcons.paperplane,
                                label: 'Share',
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: context.sp(18)),
        SizedBox(width: context.wp(1.5)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: context.sp(13),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Displays an animated Wefaq-branded shimmer sweep across placeholder shapes.
class WefaqShimmer extends StatefulWidget {
  const WefaqShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<WefaqShimmer> createState() => _WefaqShimmerState();
}

class _WefaqShimmerState extends State<WefaqShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final offset = -1.5 + (_controller.value * 3.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(offset - 1.0, -0.2),
              end: Alignment(offset + 1.0, 0.2),
              colors: const [
                Color(0xFFECE9E0),
                AppColors.surfaceWhite,
                AppColors.tagBackground,
                Color(0xFFECE9E0),
              ],
              stops: const [0.1, 0.45, 0.65, 0.9],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Rectangular skeleton placeholder block for shimmer loading layouts.
class WefaqShimmerBox extends StatelessWidget {
  const WefaqShimmerBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = AppSpacing.radiusSm,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton list of Wefaq-style cards shown while questions or activities load.
class WefaqCardListShimmer extends StatelessWidget {
  const WefaqCardListShimmer({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const WefaqShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    WefaqShimmerBox(
                      height: 22,
                      width: 84,
                      borderRadius: AppSpacing.radiusPill,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    WefaqShimmerBox(
                      height: 22,
                      width: 68,
                      borderRadius: AppSpacing.radiusPill,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                WefaqShimmerBox(height: 18, width: 240),
                SizedBox(height: AppSpacing.sm),
                WefaqShimmerBox(height: 14),
                SizedBox(height: AppSpacing.xs),
                WefaqShimmerBox(height: 14, width: 170),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact inline shimmer placeholder for setup counters and status banners.
class WefaqInlineShimmer extends StatelessWidget {
  const WefaqInlineShimmer({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    return WefaqShimmer(
      child: WefaqShimmerBox(height: height, borderRadius: AppSpacing.radiusMd),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FitnessHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final VoidCallback? onTap;
  final bool showPulse;

  const FitnessHero({
    Key? key,
    required this.tag,
    required this.child,
    this.onTap,
    this.showPulse = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showPulse && animation.value > 0.5)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentColor.withOpacity(0.2 * animation.value),
                            AppTheme.accentColor.withOpacity(0),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  child!,
                ],
              ),
            );
          },
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
} 
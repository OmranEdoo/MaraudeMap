import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';

enum AppHelpPlacement { above, below }

class AppHelpTarget {
  AppHelpTarget({
    required this.targetKey,
    required this.title,
    required this.description,
    this.placement = AppHelpPlacement.below,
    this.onTargetTap,
    this.advanceAfterTap = true,
    this.closeAfterTap = false,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final AppHelpPlacement placement;
  final VoidCallback? onTargetTap;
  final bool advanceAfterTap;
  final bool closeAfterTap;
}

class AppHelpButton extends StatelessWidget {
  const AppHelpButton({
    super.key,
    required this.targets,
  });

  final List<AppHelpTarget> targets;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aide',
      icon: const Icon(Icons.help_outline),
      onPressed: targets.isEmpty
          ? null
          : () => showAppHelpOverlay(context, targets),
    );
  }
}

Future<void> showAppHelpOverlay(
  BuildContext context,
  List<AppHelpTarget> targets,
) {
  final visibleTargets = targets.where((target) {
    final targetContext = target.targetKey.currentContext;
    final renderObject = targetContext?.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize;
  }).toList();

  if (visibleTargets.isEmpty) {
    return Future<void>.value();
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer l aide',
    barrierColor: Colors.black.withOpacity(0.64),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, __) {
      return _AppHelpOverlay(targets: visibleTargets);
    },
  );
}

class _AppHelpOverlay extends StatefulWidget {
  const _AppHelpOverlay({required this.targets});

  final List<AppHelpTarget> targets;

  @override
  State<_AppHelpOverlay> createState() => _AppHelpOverlayState();
}

class _AppHelpOverlayState extends State<_AppHelpOverlay> {
  static const _postCloseActionDelay = Duration(milliseconds: 220);
  int _currentIndex = 0;

  AppHelpTarget get _currentTarget => widget.targets[_currentIndex];

  Rect? _targetRect(GlobalKey key) {
    final targetContext = key.currentContext;
    final renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }

    final offset = renderObject.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderObject.size.width,
      renderObject.size.height,
    );
  }

  double _measureTextHeight({
    required BuildContext context,
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return painter.size.height;
  }

  double _estimateCardHeight({
    required BuildContext context,
    required double cardWidth,
    required String title,
    required String description,
  }) {
    const horizontalPadding = 36.0;
    final textWidth = math.max(120.0, cardWidth - horizontalPadding);
    final titleHeight = _measureTextHeight(
      context: context,
      text: title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimaryColor,
        decoration: TextDecoration.none,
      ),
      maxWidth: textWidth,
    );
    final descriptionHeight = _measureTextHeight(
      context: context,
      text: description,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppTheme.textSecondaryColor,
        decoration: TextDecoration.none,
      ),
      maxWidth: textWidth,
    );

    const chromeHeight = 140.0;
    return chromeHeight + titleHeight + descriptionHeight;
  }

  void _goToNext() {
    if (_currentIndex >= widget.targets.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentIndex += 1;
    });
  }

  void _goToPrevious() {
    if (_currentIndex == 0) {
      return;
    }

    setState(() {
      _currentIndex -= 1;
    });
  }

  void _handleTargetTap() {
    final target = _currentTarget;

    if (target.closeAfterTap) {
      Navigator.of(context).pop();
      if (target.onTargetTap != null) {
        Future<void>.delayed(_postCloseActionDelay, () {
          target.onTargetTap?.call();
        });
      }
      return;
    }

    target.onTargetTap?.call();

    if (target.advanceAfterTap) {
      _goToNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.of(context).padding;
    final targetRect = _targetRect(_currentTarget.targetKey);

    if (targetRect == null) {
      return const SizedBox.shrink();
    }

    final spotlightRect = Rect.fromLTWH(
      targetRect.left - 8,
      targetRect.top - 8,
      math.max(targetRect.width + 16, 48),
      math.max(targetRect.height + 16, 40),
    );

    final horizontalMargin = screenSize.width < 360 ? 8.0 : 16.0;
    final desiredCardWidth = _currentTarget.description.length > 180
        ? 460.0
        : _currentTarget.description.length > 110
            ? 400.0
            : 320.0;
    final cardWidth = math.min(
      desiredCardWidth,
      screenSize.width - (horizontalMargin * 2),
    );
    final left = (targetRect.center.dx - (cardWidth / 2)).clamp(
      horizontalMargin,
      screenSize.width - cardWidth - horizontalMargin,
    );

    var placement = _currentTarget.placement;
    final availableAbove = targetRect.top - viewPadding.top;
    final availableBelow =
        screenSize.height - viewPadding.bottom - targetRect.bottom;
    if (placement == AppHelpPlacement.above && availableAbove < 200) {
      placement = AppHelpPlacement.below;
    } else if (placement == AppHelpPlacement.below && availableBelow < 200) {
      placement = AppHelpPlacement.above;
    }

    final maxAvailableCardHeight = placement == AppHelpPlacement.above
        ? math.max(180.0, targetRect.top - viewPadding.top - 60)
        : math.max(
            180.0,
            screenSize.height - viewPadding.bottom - targetRect.bottom - 50,
          );
    final estimatedCardHeight = _estimateCardHeight(
      context: context,
      cardWidth: cardWidth,
      title: _currentTarget.title,
      description: _currentTarget.description,
    );
    final hardMaxCardHeight = math.min(
      maxAvailableCardHeight,
      screenSize.height * 0.94,
    );
    final cardHeight = math.min(
      hardMaxCardHeight,
      math.max(280.0, estimatedCardHeight + 48.0),
    );

    final top = placement == AppHelpPlacement.above
        ? math.max(
            viewPadding.top + 8,
            targetRect.top - cardHeight - 36,
          )
        : math.min(
            screenSize.height - cardHeight - viewPadding.bottom - 8,
            targetRect.bottom + 28,
          );

    final cardAnchor = placement == AppHelpPlacement.above
        ? Offset(left + (cardWidth * 0.7), top + cardHeight - 22)
        : Offset(left + (cardWidth * 0.3), top + 22);
    final targetAnchor = placement == AppHelpPlacement.above
        ? Offset(targetRect.center.dx, targetRect.top - 4)
        : Offset(targetRect.center.dx, targetRect.bottom + 4);

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: CustomPaint(
                painter: _SpotlightPainter(spotlightRect: spotlightRect),
              ),
            ),
          ),
          Positioned(
            left: spotlightRect.left,
            top: spotlightRect.top,
            width: spotlightRect.width,
            height: spotlightRect.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTargetTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CurvedArrowPainter(
                  start: cardAnchor,
                  end: targetAnchor,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: left,
            width: cardWidth,
            child: _CoachCard(
              maxHeight: cardHeight,
              title: _currentTarget.title,
              description: _currentTarget.description,
              stepIndex: _currentIndex,
              totalSteps: widget.targets.length,
              canGoBack: _currentIndex > 0,
              isLastStep: _currentIndex == widget.targets.length - 1,
              onPrevious: _goToPrevious,
              onNext: _goToNext,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.maxHeight,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.canGoBack,
    required this.isLastStep,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  final double maxHeight;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final bool canGoBack;
  final bool isLastStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxHeight,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${stepIndex + 1}/$totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textSecondaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (canGoBack)
                _CoachArrowButton(
                  label: '<',
                  onTap: onPrevious,
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              if (!isLastStep)
                _CoachArrowButton(
                  label: '>',
                  onTap: onNext,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachArrowButton extends StatelessWidget {
  const _CoachArrowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.spotlightRect});

  final Rect spotlightRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          spotlightRect,
          const Radius.circular(18),
        ),
      );

    final combined = Path.combine(
      PathOperation.difference,
      overlayPath,
      spotlightPath,
    );

    canvas.drawPath(
      combined,
      Paint()..color = Colors.black.withOpacity(0.64),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect;
  }
}

class _CurvedArrowPainter extends CustomPainter {
  const _CurvedArrowPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final deltaY = end.dy - start.dy;
    final sidePull = math.max(56.0, (start.dx - end.dx).abs() * 0.35 + 42.0);
    final arcLift = math.max(28.0, deltaY.abs() * 0.22);
    final controlPoint1 = Offset(
      start.dx - sidePull,
      start.dy + (deltaY * 0.12),
    );
    final controlPoint2 = Offset(
      end.dx - sidePull * 0.32,
      end.dy - (deltaY > 0 ? arcLift : -arcLift),
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(
      math.max(0.0, metric.length - 6.0),
    );
    if (tangent == null) {
      return;
    }

    final direction = tangent.vector;
    final directionLength = math.max(
      math.sqrt(
        (direction.dx * direction.dx) + (direction.dy * direction.dy),
      ),
      0.001,
    );
    final backVector = Offset(
      -direction.dx / directionLength,
      -direction.dy / directionLength,
    );

    Offset rotate(Offset vector, double angle) {
      final cosAngle = math.cos(angle);
      final sinAngle = math.sin(angle);
      return Offset(
        (vector.dx * cosAngle) - (vector.dy * sinAngle),
        (vector.dx * sinAngle) + (vector.dy * cosAngle),
      );
    }

    const arrowLength = 18.0;
    final wing1 = rotate(backVector, 0.5);
    final wing2 = rotate(backVector, -0.5);
    final arrowPoint1 = Offset(
      end.dx + (wing1.dx * arrowLength),
      end.dy + (wing1.dy * arrowLength),
    );
    final arrowPoint2 = Offset(
      end.dx + (wing2.dx * arrowLength),
      end.dy + (wing2.dy * arrowLength),
    );

    final arrowHead = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArrowPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}

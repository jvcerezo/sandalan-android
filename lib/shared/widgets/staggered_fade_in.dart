import 'package:flutter/material.dart';

/// Wraps a child with a staggered fade+slide-up animation.
/// Use in lists to create a cascading entrance effect.
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredFadeIn({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger the start
    final delay = widget.baseDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

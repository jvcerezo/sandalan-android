import 'package:flutter/material.dart';

/// Shimmer loading placeholder that animates a gradient sweep.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer skeleton for a card.
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShimmerLoading(height: height, borderRadius: 12),
    );
  }
}

/// Shimmer skeleton for a list of rows (like transactions).
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({super.key, this.itemCount = 5, this.itemHeight = 56});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(itemCount, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            ShimmerLoading(width: 36, height: 36, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ShimmerLoading(height: 12, width: 120, borderRadius: 4),
                const SizedBox(height: 6),
                ShimmerLoading(height: 10, width: 80, borderRadius: 4),
              ]),
            ),
            ShimmerLoading(width: 60, height: 14, borderRadius: 4),
          ]),
        )),
      ),
    );
  }
}

/// Shimmer skeleton for the balance card.
class ShimmerBalanceCard extends StatelessWidget {
  const ShimmerBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ShimmerLoading(height: 12, width: 80, borderRadius: 4),
          const SizedBox(height: 8),
          const ShimmerLoading(height: 28, width: 160, borderRadius: 6),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 28, borderRadius: 6)),
            const SizedBox(width: 16),
            Expanded(child: ShimmerLoading(height: 28, borderRadius: 6)),
          ]),
        ]),
      ),
    );
  }
}

/// Shimmer for a row of stat cards.
class ShimmerStatRow extends StatelessWidget {
  final int count;

  const ShimmerStatRow({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) => [
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: ShimmerLoading(height: 60, borderRadius: 12)),
      ]).expand((e) => e).toList(),
    );
  }
}

import 'package:flutter/material.dart';

class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
    this.iconData = Icons.shopping_cart_outlined,
    this.isCompact = false,
  });

  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData iconData;
  final bool isCompact;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? 16.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            Semantics(
              label: widget.message,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(widget.isCompact ? 15 : 30),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(
                          alpha: 0.1 * _fadeAnimation.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.iconData,
                        size: widget.isCompact ? 40 : 80,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: _fadeAnimation.value),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: widget.isCompact ? 16 : 32),
            ExcludeSemantics(
              child: Column(
                children: [
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.subMessage!,
                      style: TextStyle(
                        fontSize: widget.isCompact ? 14 : 16,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              SizedBox(height: widget.isCompact ? 16 : 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onAction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

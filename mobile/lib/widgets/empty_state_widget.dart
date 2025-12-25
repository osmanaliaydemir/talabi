import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';

class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
    this.iconData = Icons.shopping_cart_outlined,
    this.isCompact = false,
    this.usePrimaryColor = true,
  });

  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData iconData;
  final bool isCompact;
  final bool usePrimaryColor;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.usePrimaryColor
        ? theme.primaryColor
        : Colors.grey;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.isCompact ? 16.0 : 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Illustration
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.isCompact ? 100 : 180,
                    height: widget.isCompact ? 100 : 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.15),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(widget.isCompact ? 16 : 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.iconData,
                          size: widget.isCompact ? 40 : 70,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: widget.isCompact ? 16 : 40),
          // Text Content
          Text(
            widget.message,
            style: AppTheme.poppins(
              fontSize: widget.isCompact ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.subMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.subMessage!,
              style: AppTheme.poppins(
                fontSize: widget.isCompact ? 14 : 16,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.actionLabel != null && widget.onAction != null) ...[
            SizedBox(height: widget.isCompact ? 24 : 40),
            SizedBox(
              width: widget.isCompact ? double.infinity : 200,
              child: ElevatedButton(
                onPressed: widget.onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  widget.actionLabel!,
                  style: AppTheme.poppins(
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
    );
  }
}

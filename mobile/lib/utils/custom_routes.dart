import 'package:flutter/material.dart';

class NoSlidePageRoute<T> extends PageRouteBuilder<T> {
  NoSlidePageRoute({required this.builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // User requested NO effect (instant).
          return child;
        },
        // Maintain state is true by default for PageRouteBuilder
        maintainState: true,
        // Set duration to zero for instant transition
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
  final WidgetBuilder builder;
}

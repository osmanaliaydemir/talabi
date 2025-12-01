import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;

  const BannerWidget({
    super.key,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.3),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Optimized cached network image widget with placeholder, error handling, and fade-in animation
///
/// This widget provides:
/// - Automatic image caching (memory and disk)
/// - Placeholder while loading
/// - Error widget on failure
/// - Fade-in animation
/// - Configurable max width/height for memory optimization
class CachedNetworkImageWidget extends StatelessWidget {
  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.placeholderColor,
    this.errorColor,
    this.maxWidth,
    this.maxHeight,
    // Flash önlemek için fade-in süresini çok kısa tut
    // Cache'den yüklenen image'ler için bile fade-in çalışıyor, bu yüzden çok kısa yapıyoruz
    this.fadeInDuration = const Duration(milliseconds: 50),
    this.fadeOutDuration = const Duration(milliseconds: 30),
    this.useOldImageOnUrlChange = true,
    // Daha yumuşak geçiş için curve (easeOut daha doğal görünür)
    this.fadeInCurve = Curves.easeOut,
    this.semanticsLabel,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Color? errorColor;
  final int? maxWidth;
  final int? maxHeight;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final bool useOldImageOnUrlChange;
  final Curve fadeInCurve;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      maxWidthDiskCache: maxWidth,
      maxHeightDiskCache: maxHeight,
      // Flash önlemek için fade-in süresini kısalt ve yumuşak curve kullan
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(),
      memCacheWidth: maxWidth,
      memCacheHeight: maxHeight,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return Semantics(
      label: semanticsLabel,
      image: semanticsLabel != null,
      child: imageWidget,
    );
  }

  Widget _buildDefaultPlaceholder() {
    // Flash önlemek için placeholder'ı daha nötr ve image'e yakın renk yap
    // Açık gri yerine biraz daha koyu, image'lerin ortalama rengine yakın
    return Container(
      width: width,
      height: height,
      // Daha nötr renk - flash önlemek için
      color: placeholderColor ?? Colors.grey[300],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              placeholderColor?.withValues(alpha: 0.6) ?? Colors.grey[500]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    // Calculate icon size safely
    double iconSize = 40.0; // Default size
    if (width != null && height != null && width! > 0 && height! > 0) {
      final calculatedSize = (width! < height! ? width! * 0.4 : height! * 0.4);
      // Ensure size is valid (finite, positive, and reasonable)
      if (calculatedSize.isFinite &&
          calculatedSize > 0 &&
          calculatedSize < 1000) {
        iconSize = calculatedSize;
      }
    }

    return Container(
      width: width,
      height: height,
      color: errorColor ?? Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: iconSize,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

/// Factory class for creating optimized cached network images with common configurations
class OptimizedCachedImage {
  /// Creates a cached network image optimized for product thumbnails
  static Widget productThumbnail({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    String? semanticsLabel,
  }) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      width: width ?? 120,
      height: height ?? 120,
      maxWidth: 300, // Optimize memory usage
      maxHeight: 300,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      // Flash önlemek için placeholder rengini daha nötr yap
      placeholderColor: Colors.grey[300],
      errorColor: Colors.grey[300],
      // Flash önlemek için çok kısa fade-in (cache'den yüklenen image'ler için bile)
      fadeInDuration: const Duration(milliseconds: 50),
      semanticsLabel: semanticsLabel,
    );
  }

  /// Creates a cached network image optimized for vendor logos
  static Widget vendorLogo({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    String? semanticsLabel,
  }) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      width: width ?? 80,
      height: height ?? 80,
      maxWidth: 200,
      maxHeight: 200,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      // Flash önlemek için placeholder rengini daha nötr yap
      placeholderColor: Colors.grey[300],
      errorColor: Colors.grey[300],
      // Flash önlemek için çok kısa fade-in (cache'den yüklenen image'ler için bile)
      fadeInDuration: const Duration(milliseconds: 50),
      semanticsLabel: semanticsLabel,
    );
  }

  /// Creates a cached network image optimized for banners
  static Widget banner({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    String? semanticsLabel,
  }) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      maxWidth: 800, // Banners can be larger
      maxHeight: 400,
      borderRadius: borderRadius,
      // Flash önlemek için placeholder rengini daha nötr yap
      placeholderColor: Colors.grey[300],
      errorColor: Colors.grey[300],
      // Flash önlemek için çok kısa fade-in (cache'den yüklenen image'ler için bile)
      fadeInDuration: const Duration(milliseconds: 50),
      semanticsLabel: semanticsLabel,
    );
  }

  /// Creates a cached network image optimized for full-size product images
  static Widget productImage({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    String? semanticsLabel,
  }) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      maxWidth: 600, // Full-size but still optimized
      maxHeight: 600,
      borderRadius: borderRadius,
      // Flash önlemek için placeholder rengini daha nötr yap
      placeholderColor: Colors.grey[300],
      errorColor: Colors.grey[300],
      // Flash önlemek için çok kısa fade-in (cache'den yüklenen image'ler için bile)
      fadeInDuration: const Duration(milliseconds: 50),
      semanticsLabel: semanticsLabel,
    );
  }
}

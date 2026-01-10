import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/categories/presentation/screens/category_products_screen.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/empty_state_widget.dart';

class HomeCategorySection extends StatelessWidget {
  const HomeCategorySection({
    super.key,
    required this.categoriesFuture,
    required this.onViewAll,
    this.hasVendors = true,
    this.hasProducts = true,
  });

  final Future<List<Map<String, dynamic>>> categoriesFuture;
  final VoidCallback onViewAll;
  final bool hasVendors;
  final bool hasProducts;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // If no vendors or products, don't show category empty state
        if (!hasVendors || !hasProducts) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingLarge,
            ),
            child: EmptyStateWidget(
              message: localizations.noCategoriesInArea,
              subMessage: localizations.noCategoriesInAreaSub,
              iconData: Icons.category_outlined,
              isCompact: true,
            ),
          );
        }

        final categories = snapshot.data!;
        // Show only first 8 categories on home screen
        final displayCategories = categories.take(8).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.categories,
                    style: AppTheme.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(localizations.viewAll),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: displayCategories.length,
                itemBuilder: (context, index) {
                  final category = displayCategories[index];
                  final style = _getCategoryStyle(
                    category,
                    primaryColor: colorScheme.primary,
                  );

                  // Try multiple keys for image
                  final imageUrl =
                      category['image'] ??
                      category['imageUrl'] ??
                      category['imgUrl'] ??
                      category['img'];

                  return Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        if (category['id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryId: category['id'],
                                categoryName: category['name'] ?? '',
                                imageUrl:
                                    imageUrl, // Pass the resolved image URL
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: imageUrl != null
                                ? EdgeInsets.zero
                                : const EdgeInsets.all(AppTheme.spacingSmall),
                            decoration: BoxDecoration(
                              color: imageUrl != null
                                  ? Colors.transparent
                                  : (style['color'] as Color).withValues(
                                      alpha: 0.1,
                                    ),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: imageUrl != null
                                  ? CachedNetworkImageWidget(
                                      imageUrl: imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      maxWidth: 120, // Optimize memory
                                      maxHeight: 120,
                                      errorWidget: Icon(
                                        style['icon'] as IconData,
                                        color: style['color'] as Color,
                                        size: 24,
                                      ),
                                    )
                                  : Icon(
                                      style['icon'] as IconData,
                                      color: style['color'] as Color,
                                      size: 24,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'] ?? '',
                            style: AppTheme.poppins(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper to get category icon and color
  Map<String, dynamic> _getCategoryStyle(
    Map<String, dynamic> category, {
    Color? primaryColor,
  }) {
    // Try to use API-provided icon and color first
    final iconString = category['icon'] as String?;
    final colorString = category['color'] as String?;

    IconData? icon;
    Color? color;

    // Map icon string to IconData if provided
    if (iconString != null && iconString.isNotEmpty) {
      icon = _getIconFromString(iconString);
    }

    // Map color string to Color if provided
    if (colorString != null && colorString.isNotEmpty) {
      color = _getColorFromString(colorString, primaryColor: primaryColor);
    }

    // If both icon and color are successfully mapped from API, use them
    if (icon != null && color != null) {
      return {'icon': icon, 'color': color};
    }

    // Fallback to name-based logic if API data is not available or mapping failed
    final name = (category['name'] as String? ?? '').toLowerCase();
    final defaultPrimary = primaryColor ?? AppTheme.primaryOrange;

    if (name.contains('yemek') ||
        name.contains('food') ||
        name.contains('طعام')) {
      return {
        'icon': icon ?? Icons.restaurant,
        'color': color ?? defaultPrimary,
      };
    } else if (name.contains('mağaza') ||
        name.contains('store') ||
        name.contains('متاجر')) {
      return {'icon': icon ?? Icons.store, 'color': color ?? Colors.blue};
    } else if (name.contains('market') ||
        name.contains('grocery') ||
        name.contains('بقالة')) {
      return {
        'icon': icon ?? Icons.shopping_basket,
        'color': color ?? Colors.green,
      };
    } else if (name.contains('içecek') ||
        name.contains('drink') ||
        name.contains('مشروبات')) {
      return {
        'icon': icon ?? Icons.local_drink,
        'color': color ?? Colors.purple,
      };
    } else if (name.contains('tatlı') ||
        name.contains('dessert') ||
        name.contains('حلويات')) {
      return {'icon': icon ?? Icons.cake, 'color': color ?? Colors.pink};
    } else if (name.contains('elektronik') ||
        name.contains('electronic') ||
        name.contains('إلكترونيات')) {
      return {'icon': icon ?? Icons.devices, 'color': color ?? Colors.indigo};
    } else if (name.contains('giyim') ||
        name.contains('clothing') ||
        name.contains('ملابس')) {
      return {'icon': icon ?? Icons.checkroom, 'color': color ?? Colors.teal};
    } else {
      return {'icon': icon ?? Icons.category, 'color': color ?? defaultPrimary};
    }
  }

  // Helper to map icon string to IconData
  IconData? _getIconFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) return null;

    // Remove FontAwesome prefixes (fa-solid fa-, fa-regular fa-, etc.)
    String cleanIconString = iconString.toLowerCase();
    if (cleanIconString.contains('fa-')) {
      final parts = cleanIconString.split('fa-');
      if (parts.length > 1) {
        cleanIconString = parts.last.split(' ').last;
      }
    }

    final iconMap = {
      'restaurant': Icons.restaurant,
      'store': Icons.store,
      'shopping_basket': Icons.shopping_basket,
      'local_drink': Icons.local_drink,
      'cake': Icons.cake,
      'cake-candles': Icons.cake,
      'drumstick-bite': Icons.restaurant_menu,
      'burger': Icons.lunch_dining,
      'pizza-slice': Icons.local_pizza,
      'devices': Icons.devices,
      'checkroom': Icons.checkroom,
      'category': Icons.category,
      'fastfood': Icons.fastfood,
      'shopping_cart': Icons.shopping_cart,
      'coffee': Icons.coffee,
      'lunch_dining': Icons.lunch_dining,
      'bakery_dining': Icons.bakery_dining,
      'local_grocery_store': Icons.local_grocery_store,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'watch': Icons.watch,
      'tshirt': Icons.checkroom,
      'clothing': Icons.checkroom,
      'shoes': Icons.shopping_bag,
      'home': Icons.home,
      'work': Icons.work,
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'beach_access': Icons.beach_access,
      'school': Icons.school,
      'book': Icons.book,
      'music_note': Icons.music_note,
      'movie': Icons.movie,
      'sports_soccer': Icons.sports_soccer,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'medical_services': Icons.medical_services,
      'car_repair': Icons.car_repair,
      'build': Icons.build,
    };

    return iconMap[cleanIconString] ??
        iconMap[cleanIconString.replaceAll('-', '_')];
  }

  // Helper to map color string to Color
  Color? _getColorFromString(String? colorString, {Color? primaryColor}) {
    if (colorString == null || colorString.isEmpty) return null;

    try {
      // Try to parse hex color (e.g., "#FF5722" or "FF5722")
      String cleanColorString = colorString.trim();
      if (cleanColorString.startsWith('#')) {
        cleanColorString = cleanColorString.substring(1);
      }
      if (cleanColorString.length == 6) {
        try {
          return Color(int.parse('FF$cleanColorString', radix: 16));
        } catch (e) {
          // If parsing fails, try named colors
        }
      }

      // Named color mapping
      final colorMap = {
        'orange': primaryColor ?? AppTheme.primaryOrange,
        'blue': Colors.blue,
        'green': Colors.green,
        'purple': Colors.purple,
        'pink': Colors.pink,
        'indigo': Colors.indigo,
        'teal': Colors.teal,
        'red': Colors.red,
        'amber': Colors.amber,
        'cyan': Colors.cyan,
        'deepOrange': Colors.deepOrange,
        'deepPurple': Colors.deepPurple,
        'lightBlue': Colors.lightBlue,
        'lightGreen': Colors.lightGreen,
        'lime': Colors.lime,
        'yellow': Colors.yellow,
        'brown': Colors.brown,
        'grey': Colors.grey,
        'gray': Colors.grey,
      };

      return colorMap[cleanColorString.toLowerCase()];
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Error parsing color: $colorString',
        e,
        stackTrace,
      );
      return null;
    }
  }
}

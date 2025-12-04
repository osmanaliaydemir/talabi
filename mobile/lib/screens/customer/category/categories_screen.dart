import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/customer/category/category_products_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/home_header.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCategories();
  }

  void _loadCategories() {
    final locale = AppLocalizations.of(context)?.localeName;
    _categoriesFuture = _apiService.getCategories(language: locale);
  }

  IconData? _getIconFromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) return null;

    final iconMap = {
      'restaurant': Icons.restaurant,
      'store': Icons.store,
      'shopping_basket': Icons.shopping_basket,
      'local_drink': Icons.local_drink,
      'cake': Icons.cake,
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

    return iconMap[iconString.toLowerCase()];
  }

  Color? _getColorFromString(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }
    if (colorString.length == 6) {
      try {
        return Color(int.parse('FF$colorString', radix: 16));
      } catch (e) {
        // If parsing fails, try named colors
      }
    }

    final colorMap = {
      'orange': AppTheme.primaryOrange,
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

    return colorMap[colorString.toLowerCase()];
  }

  Map<String, dynamic> _getCategoryStyle(Map<String, dynamic> category) {
    final iconString = category['icon'] as String?;
    final colorString = category['color'] as String?;

    IconData? icon;
    Color? color;

    if (iconString != null && iconString.isNotEmpty) {
      icon = _getIconFromString(iconString);
    }

    if (colorString != null && colorString.isNotEmpty) {
      color = _getColorFromString(colorString);
    }

    if (icon != null && color != null) {
      return {'icon': icon, 'color': color};
    }

    final name = (category['name'] as String).toLowerCase();

    if (name.contains('yemek') ||
        name.contains('food') ||
        name.contains('طعام')) {
      return {
        'icon': icon ?? Icons.restaurant,
        'color': color ?? AppTheme.primaryOrange,
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
      return {'icon': icon ?? Icons.category, 'color': color ?? Colors.orange};
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          HomeHeader(
            title: localizations.categories,
            subtitle: localizations.discover,
            leadingIcon: Icons.category,
            showBackButton: true,
            showCart: true,
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          localizations.categoryNotFound,
                          style: AppTheme.poppins(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final categories = snapshot.data!;
                // Sort by displayOrder if available, then by name
                final sortedCategories =
                    List<Map<String, dynamic>>.from(categories)..sort((a, b) {
                      final orderA = a['displayOrder'] as int? ?? 999;
                      final orderB = b['displayOrder'] as int? ?? 999;
                      if (orderA != orderB) {
                        return orderA.compareTo(orderB);
                      }
                      final nameA = (a['name'] as String).toLowerCase();
                      final nameB = (b['name'] as String).toLowerCase();
                      return nameA.compareTo(nameB);
                    });
                return RefreshIndicator(
                  color: AppTheme.primaryOrange,
                  onRefresh: () async {
                    setState(() {
                      _loadCategories();
                    });
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.all(AppTheme.spacingMedium),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 2.1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final category = sortedCategories[index];
                      return _buildCategoryCard(category);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final categoryName = category['name'] as String;
    final style = _getCategoryStyle(category);
    final icon = style['icon'] as IconData;
    final color = style['color'] as Color;
    final imageUrl = category['imageUrl']?.toString();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryName: categoryName,
              categoryId: category['id']?.toString(),
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Layer
              if (hasImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackBackground(color, icon);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppTheme.cardColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: color,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              else
                _buildFallbackBackground(color, icon),

              // Gradient Overlay (only if hasImage)
              if (hasImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

              // Content Layer
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBackground(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.8), color],
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withOpacity(0.5), size: 64),
      ),
    );
  }
}

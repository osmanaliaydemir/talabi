import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/search/presentation/providers/search_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:provider/provider.dart';

class SearchFilterSheet extends StatelessWidget {
  const SearchFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<SearchProvider>();
    final bottomNav = context.read<BottomNavProvider>();

    final primaryColor = bottomNav.selectedCategory == MainCategory.restaurant
        ? AppTheme.primaryOrange
        : AppTheme.marketPrimary;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingSmall,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filters,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    searchProvider.clearFilters();
                    // Note: Search relies on caller to trigger search if filters cleared immediately?
                    // Or just clear state. Usually "Apply" triggers fetch.
                    // But clearing might want immediate effect if "Apply" is only for "Set".
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n.clear,
                    style: AppTheme.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  if (searchProvider.categories.isNotEmpty) ...[
                    Text(
                      l10n.category,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    InputDecorator(
                      decoration: AppTheme.inputDecoration(
                        hint: l10n.selectCategory,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: searchProvider.selectedCategoryId,
                          isDense: true,
                          isExpanded: true,
                          hint: Text(l10n.selectCategory),
                          items: searchProvider.categories.map((category) {
                            return DropdownMenuItem(
                              value: category['id'].toString(),
                              child: Text(category['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            searchProvider.setFilters(categoryId: value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],

                  // Price Range
                  Text(
                    l10n.priceRange,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                            hint: l10n.minPrice,
                          ),
                          onChanged: (val) => searchProvider.setFilters(
                            minPrice: double.tryParse(val),
                          ),
                          controller: TextEditingController(
                            text: searchProvider.minPrice?.toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration(
                            hint: l10n.maxPrice,
                          ),
                          onChanged: (val) => searchProvider.setFilters(
                            maxPrice: double.tryParse(val),
                          ),
                          controller: TextEditingController(
                            text: searchProvider.maxPrice?.toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),

                  // City
                  if (searchProvider.cities.isNotEmpty) ...[
                    Text(
                      l10n.city,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    InputDecorator(
                      decoration: AppTheme.inputDecoration(
                        hint: l10n.selectCity,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: searchProvider.selectedCity,
                          isDense: true,
                          isExpanded: true,
                          hint: Text(l10n.selectCity),
                          items: searchProvider.cities
                              .map(
                                (city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              searchProvider.setFilters(city: val),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],

                  // Sort By
                  Text(
                    l10n.sortBy,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  InputDecorator(
                    decoration: AppTheme.inputDecoration(
                      hint: l10n.selectSortBy,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: searchProvider.sortBy,
                        isDense: true,
                        isExpanded: true,
                        hint: Text(l10n.selectSortBy),
                        items: [
                          DropdownMenuItem(
                            value: 'price_asc',
                            child: Text(l10n.priceLowToHigh),
                          ),
                          DropdownMenuItem(
                            value: 'price_desc',
                            child: Text(l10n.priceHighToLow),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(l10n.sortByName),
                          ),
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text(l10n.newest),
                          ),
                        ],
                        onChanged: (val) =>
                            searchProvider.setFilters(sortBy: val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(
                top: BorderSide(color: AppTheme.dividerColor, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  ); // Return result to trigger search
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                ),
                child: Text(
                  l10n.applyFilters,
                  style: AppTheme.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

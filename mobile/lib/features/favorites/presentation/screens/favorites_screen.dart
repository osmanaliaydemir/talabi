import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/features/profile/presentation/screens/customer/profile_screen.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _favorites = [];

  // Pagination State
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  int? _lastBottomNavIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadFavorites(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isFirstLoad) {
      _loadMoreFavorites();
    }
  }

  Future<void> _loadFavorites({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _favorites.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _apiService.getFavorites(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _favorites = result.items.map((dto) => dto.toProduct()).toList();
          } else {
            _favorites.addAll(
              result.items.map((dto) => dto.toProduct()).toList(),
            );
          }

          _isFirstLoad = false;
          _isLoadingMore = false;

          _hasMoreData =
              result.items.length >= _pageSize &&
              _favorites.length < result.totalCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Favoriler yüklenemedi: $e')));
      }
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_isLoadingMore || !_hasMoreData) return;
    _currentPage++;
    await _loadFavorites(isRefresh: false);
  }

  Future<void> _removeFromFavorites(String productId) async {
    try {
      await _apiService.removeFromFavorites(productId);
      setState(() {
        _favorites.removeWhere((p) => p.id == productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorilerden kaldırıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNav = Provider.of<BottomNavProvider>(context);

    // Check if favorites screen just became visible
    if (bottomNav.currentIndex == 1 && _lastBottomNavIndex != 1) {
      // Screen just became visible, reload favorites
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFavorites(isRefresh: true);
      });
    }
    _lastBottomNavIndex = bottomNav.currentIndex;

    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: localizations.myFavorites,
            subtitle: '${_favorites.length} ${localizations.favorites}',
            icon: Icons.favorite,
            showBackButton: true,
            onBack: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
          ),
          // Main Content
          Expanded(
            child: _isFirstLoad
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return const ProductSkeletonItem();
                    },
                  )
                : _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz favori ürününüz yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                        ),
                    cacheExtent: 500.0, // Optimize cache extent
                    addAutomaticKeepAlives: false, // Improve performance
                    addRepaintBoundaries: true, // Optimize repaints
                    itemCount: _favorites.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _favorites.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final product = _favorites[index];
                      return RepaintBoundary(
                        child: ProductCard(
                          product: product,
                          width: null,
                          isFavorite: true,
                          rating: '4.7',
                          ratingCount: '2.3k',
                          onFavoriteTap: () => _removeFromFavorites(product.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';

enum MainCategory { restaurant, market }

class BottomNavProvider with ChangeNotifier {
  int _currentIndex = 0;
  MainCategory _selectedCategory = MainCategory.restaurant;

  int get currentIndex => _currentIndex;
  MainCategory get selectedCategory => _selectedCategory;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setCategory(MainCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void reset() {
    _currentIndex = 0;
    _selectedCategory = MainCategory.restaurant;
    notifyListeners();
  }
}

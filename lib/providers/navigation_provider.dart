import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() => setIndex(0);
  void goToFavorites() => setIndex(1);
  void goToMessages() => setIndex(2);
  void goToProfile() => setIndex(3);
}

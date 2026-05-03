import 'package:flutter/material.dart';
import '../data/models/status_model.dart';

class HomeViewModel extends ChangeNotifier {
  final List<String> categories = ['Good Morning', 'Bhakti', 'Shayari', 'Motivation', 'Love'];
  String _selectedCategory = 'Good Morning';

  String get selectedCategory => _selectedCategory;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Mock Data
  List<StatusModel> get statuses {
    return [
      StatusModel(
        id: '1',
        imageUrl: 'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&q=80&w=1200',
        text: 'Rise and shine! Every new dawn is a second chance at happiness. ☀️',
        category: 'Good Morning',
      ),
      StatusModel(
        id: '2',
        imageUrl: 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&q=80&w=1200',
        text: 'A beautiful morning brings a beautiful day. 🌅',
        category: 'Good Morning',
      ),
    ].where((status) => status.category == _selectedCategory).toList();
  }
}

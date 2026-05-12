import 'package:flutter/material.dart';
import '../data/models/status_model.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Map<String, String>> categories = [
    {
      'name': 'Good Morning',
      'image': 'assets/images/bhakti.png'
    },
    {
      'name': 'Bhakti',
      'image': 'assets/images/bhakti.png'
    },
    {
      'name': 'Shayari',
      'image': 'assets/images/shayari.png'
    },
    {
      'name': 'Motivation',
      'image': 'assets/images/shayari.png'
    },
    {
      'name': 'Love',
      'image': 'assets/images/bhakti.png'
    },
  ];
  
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
        imageUrl: 'assets/images/bhakti.png',
        text: 'Rise and shine! Every new dawn is a second chance at happiness. ☀️',
        category: 'Good Morning',
      ),
      StatusModel(
        id: '2',
        imageUrl: 'assets/images/shayari.png',
        text: 'A beautiful morning brings a beautiful day. 🌅',
        category: 'Good Morning',
      ),
      StatusModel(
        id: '3',
        imageUrl: 'assets/images/bhakti.png',
        text: 'Peace begins with a smile. 🙏',
        category: 'Bhakti',
      ),
    ].where((status) => status.category == _selectedCategory).toList();
  }
}

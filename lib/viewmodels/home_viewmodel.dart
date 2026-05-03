import 'package:flutter/material.dart';
import '../data/models/status_model.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Map<String, String>> categories = [
    {
      'name': 'Good Morning',
      'image': 'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Bhakti',
      'image': 'https://images.unsplash.com/photo-1582508107770-5b5c777d12f3?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Shayari',
      'image': 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Motivation',
      'image': 'https://images.unsplash.com/photo-1552581234-26160f608093?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Love',
      'image': 'https://images.unsplash.com/photo-1518199266791-5375a83164ba?auto=format&fit=crop&q=80&w=300'
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
      StatusModel(
        id: '3',
        imageUrl: 'https://images.unsplash.com/photo-1582508107770-5b5c777d12f3?auto=format&fit=crop&q=80&w=1200',
        text: 'Peace begins with a smile. 🙏',
        category: 'Bhakti',
      ),
    ].where((status) => status.category == _selectedCategory).toList();
  }
}

import 'package:compareitr/core/common/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    required super.categoryName,
    required super.categoryUrl,
    required super.shopName,
    required super.id,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryName: json['category_name'] ?? '',  // Changed from 'categoryName' to 'category_name'
      categoryUrl: json['category_url'] ?? '',    // Changed from 'categoryUrl' to 'category_url'
      shopName: json['shopName'] ?? '',           // This is set in the data source
      id: json['id'] ?? '',
    );
  }
}

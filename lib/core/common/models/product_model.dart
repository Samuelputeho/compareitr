import 'package:compareitr/core/common/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    required super.measure,
    required super.imageUrl,
    required super.price,
    required super.salePrice,
    required super.description,
    required super.shopName,
    required super.category,
    required super.subCategory,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',                // Fixed: back to 'name'
      measure: json['measure'] ?? '',
      imageUrl: json['imageUrl'] ?? '',        // Fixed: back to 'imageUrl'
      price: (json['price'] ?? 0).toDouble(),  // Fixed: convert to double
      salePrice: (json['salePrice'] ?? 0).toDouble(), // Fixed: convert to double
      description: json['description'] ?? '',
      shopName: json['shopName'] ?? '',        // This is set in the data source
      category: json['category'] ?? '',        // This is set in the data source
      subCategory: json['subCategory'] ?? '',  // Fixed: back to 'subCategory'
    );
  }
}

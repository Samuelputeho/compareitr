import '../entities/branch_entity.dart';

class BranchModel extends BranchEntity {
  BranchModel({
    required super.id,
    required super.branchName,
    required super.shopId,
    super.address,
    super.phoneNumber,
  });

  // from json
  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',  // Changed from 'branchName' to 'branch_name'
      shopId: json['shop_id'] as String? ?? '',          // Changed from 'shopId' to 'shop_id'
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String?,      // Changed from 'phoneNumber' to 'phone_number'
    );
  }
}

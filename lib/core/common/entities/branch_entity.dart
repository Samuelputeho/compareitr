class BranchEntity {
  final String id;
  final String branchName;
  final String shopId;
  final String? address;
  final String? phoneNumber;

  BranchEntity({
    required this.id,
    required this.branchName,
    required this.shopId,
    this.address,
    this.phoneNumber,
  });
}

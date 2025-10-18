import 'package:compareitr/core/usecase/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/branch_entity.dart';
import '../../../../core/error/failures.dart';
import '../repository/repo.dart';

class GetBranchesByShopUsecase implements UseCase<List<BranchEntity>, String> {
  final ShopsRepository repository;

  GetBranchesByShopUsecase(this.repository);

  @override
  Future<Either<Failure, List<BranchEntity>>> call(String shopId) async {
    return repository.getBranchesByShopId(shopId);
  }
}

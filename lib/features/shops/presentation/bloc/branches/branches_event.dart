part of 'branches_bloc.dart';

@immutable
sealed class BranchesEvent {}

class GetBranchesByShopEvent extends BranchesEvent {
  final String shopId;
  
  GetBranchesByShopEvent({required this.shopId});
}

class SelectBranchEvent extends BranchesEvent {
  final BranchEntity branch;
  
  SelectBranchEvent({required this.branch});
}

class ClearBranchSelectionEvent extends BranchesEvent {}

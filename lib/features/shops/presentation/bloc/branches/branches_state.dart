part of 'branches_bloc.dart';

@immutable
sealed class BranchesState {}

final class BranchesInitial extends BranchesState {}

final class BranchesLoading extends BranchesState {}

final class BranchesSuccess extends BranchesState {
  final List<BranchEntity> branches;
  final BranchEntity? selectedBranch;

  BranchesSuccess({required this.branches, this.selectedBranch});
}

final class BranchesFailure extends BranchesState {
  final String message;

  BranchesFailure({required this.message});
}

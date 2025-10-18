import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/common/entities/branch_entity.dart';
import '../../../domain/usecase/get_branches_by_shop.dart';

part 'branches_event.dart';
part 'branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  final GetBranchesByShopUsecase _getBranchesByShopUsecase;

  BranchesBloc({required GetBranchesByShopUsecase getBranchesByShopUsecase})
      : _getBranchesByShopUsecase = getBranchesByShopUsecase,
        super(BranchesInitial()) {
    on<BranchesEvent>((event, emit) {});
    on<GetBranchesByShopEvent>(_onGetBranchesByShop);
    on<SelectBranchEvent>(_onSelectBranch);
    on<ClearBranchSelectionEvent>(_onClearBranchSelection);
  }

  void _onGetBranchesByShop(
    GetBranchesByShopEvent event,
    Emitter<BranchesState> emit,
  ) async {
    print("Getting branches for shopId: ${event.shopId}");
    emit(BranchesLoading());
    final res = await _getBranchesByShopUsecase(event.shopId);

    res.fold(
      (l) {
        print("Branches fetch failed: ${l.message}");
        emit(BranchesFailure(message: l.message));
      },
      (r) {
        print("Number of branches fetched: ${r.length}");
        for (var branch in r) {
          print("Branch: ${branch.branchName} (ID: ${branch.id})");
        }
        emit(BranchesSuccess(branches: r));
      },
    );
  }

  void _onSelectBranch(
    SelectBranchEvent event,
    Emitter<BranchesState> emit,
  ) {
    if (state is BranchesSuccess) {
      final currentState = state as BranchesSuccess;
      emit(BranchesSuccess(
        branches: currentState.branches,
        selectedBranch: event.branch,
      ));
    }
  }

  void _onClearBranchSelection(
    ClearBranchSelectionEvent event,
    Emitter<BranchesState> emit,
  ) {
    if (state is BranchesSuccess) {
      final currentState = state as BranchesSuccess;
      emit(BranchesSuccess(
        branches: currentState.branches,
        selectedBranch: null,
      ));
    }
  }
}

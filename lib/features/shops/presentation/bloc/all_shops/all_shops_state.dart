part of 'all_shops_bloc.dart';

@immutable
sealed class AllShopsState {}

final class AllShopsInitial extends AllShopsState {}

final class AllShopsLoading extends AllShopsState {
  final List<ShopEntity> loadingShops;
  AllShopsLoading({required this.loadingShops});
}

final class AllShopsSuccess extends AllShopsState {
  final List<ShopEntity> shops;
  final String? currentFilter;

  AllShopsSuccess({required this.shops, this.currentFilter});
}

final class AllShopsFailure extends AllShopsState {
  final String message;

  AllShopsFailure({required this.message});
}

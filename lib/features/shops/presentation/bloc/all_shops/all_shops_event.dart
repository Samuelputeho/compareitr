part of 'all_shops_bloc.dart';

@immutable
sealed class AllShopsEvent {}

class GetAllShopsEvent extends AllShopsEvent {}

class FilterShopsByTypeEvent extends AllShopsEvent {
  final String? shopType;
  
  FilterShopsByTypeEvent({this.shopType});
}

class ClearShopFilterEvent extends AllShopsEvent {}

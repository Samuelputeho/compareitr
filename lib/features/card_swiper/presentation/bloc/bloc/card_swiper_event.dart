part of 'card_swiper_bloc.dart';

@immutable
sealed class CardSwiperEvent {}

class GetAllCardSwiperPicturesEvent extends CardSwiperEvent {}

class RefreshCardSwiperPicturesEvent extends CardSwiperEvent {}

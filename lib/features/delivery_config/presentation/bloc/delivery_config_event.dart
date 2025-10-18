import 'package:equatable/equatable.dart';

abstract class DeliveryConfigEvent extends Equatable {
  const DeliveryConfigEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryConfig extends DeliveryConfigEvent {
  const LoadDeliveryConfig();
}

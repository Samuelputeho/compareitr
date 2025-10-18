import 'package:equatable/equatable.dart';
import 'package:compareitr/features/delivery_config/domain/entities/delivery_config_entity.dart';

abstract class DeliveryConfigState extends Equatable {
  const DeliveryConfigState();

  @override
  List<Object?> get props => [];
}

class DeliveryConfigInitial extends DeliveryConfigState {}

class DeliveryConfigLoading extends DeliveryConfigState {}

class DeliveryConfigLoaded extends DeliveryConfigState {
  final DeliveryConfigEntity config;

  const DeliveryConfigLoaded({required this.config});

  @override
  List<Object?> get props => [config];
}

class DeliveryConfigError extends DeliveryConfigState {
  final String message;

  const DeliveryConfigError({required this.message});

  @override
  List<Object?> get props => [message];
}

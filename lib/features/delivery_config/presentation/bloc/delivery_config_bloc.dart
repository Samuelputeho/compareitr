import 'package:bloc/bloc.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/delivery_config/domain/usecases/get_delivery_config.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_event.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_state.dart';
import 'package:equatable/equatable.dart';

class DeliveryConfigBloc extends Bloc<DeliveryConfigEvent, DeliveryConfigState> {
  final GetDeliveryConfig getDeliveryConfig;

  DeliveryConfigBloc({required this.getDeliveryConfig}) : super(DeliveryConfigInitial()) {
    on<LoadDeliveryConfig>(_onLoadDeliveryConfig);
  }

  Future<void> _onLoadDeliveryConfig(
    LoadDeliveryConfig event,
    Emitter<DeliveryConfigState> emit,
  ) async {
    emit(DeliveryConfigLoading());

    final result = await getDeliveryConfig();

    result.fold(
      (failure) => emit(DeliveryConfigError(message: _mapFailureToMessage(failure))),
      (config) => emit(DeliveryConfigLoaded(config: config)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message.isNotEmpty 
        ? '${failure.message}. Using default delivery time.'
        : 'An unexpected error occurred. Using default delivery time.';
  }
}

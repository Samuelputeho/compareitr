import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/features/delivery_config/data/models/delivery_config_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DeliveryConfigRemoteDataSource {
  Future<DeliveryConfigModel> getDeliveryConfig();
}

class DeliveryConfigRemoteDataSourceImpl implements DeliveryConfigRemoteDataSource {
  final SupabaseClient supabaseClient;

  DeliveryConfigRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<DeliveryConfigModel> getDeliveryConfig() async {
    try {
      final response = await supabaseClient
          .from('app_settings')
          .select()
          .eq('setting_key', 'delivery_time_minutes')
          .maybeSingle();

      if (response != null) {
        return DeliveryConfigModel.fromJson(response);
      } else {
        // Return default config if not found in database
        return DeliveryConfigModel(
          deliveryTimeMinutes: 90,
          lastUpdated: DateTime.now(),
        );
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

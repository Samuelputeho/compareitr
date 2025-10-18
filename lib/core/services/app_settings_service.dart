import 'package:compareitr/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSettingsService {
  final SupabaseClient _supabaseClient;

  AppSettingsService({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  /// Fetch a specific app setting by key
  Future<String?> getSetting(String settingKey) async {
    try {
      final response = await _supabaseClient
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', settingKey)
          .maybeSingle();

      if (response != null) {
        return response['setting_value'] as String?;
      }
      return null;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch app setting: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error fetching app setting: $e');
    }
  }

  /// Fetch multiple app settings by keys
  Future<Map<String, String>> getSettings(List<String> settingKeys) async {
    try {
      final response = await _supabaseClient
          .from('app_settings')
          .select('setting_key, setting_value')
          .inFilter('setting_key', settingKeys);

      final Map<String, String> settings = {};
      for (final item in response) {
        settings[item['setting_key'] as String] = item['setting_value'] as String;
      }
      return settings;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to fetch app settings: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error fetching app settings: $e');
    }
  }

  /// Fetch support email with fallback
  Future<String> getSupportEmail() async {
    try {
      final email = await getSetting('support_email');
      return email ?? 'support@compareitr.com'; // Fallback email
    } catch (e) {
      return 'support@compareitr.com'; // Fallback email on error
    }
  }

  /// Fetch delivery time with fallback
  Future<int> getDeliveryTimeMinutes() async {
    try {
      final time = await getSetting('delivery_time_minutes');
      return int.tryParse(time ?? '90') ?? 90; // Default 90 minutes
    } catch (e) {
      return 90; // Fallback on error
    }
  }

  /// Fetch default service fee percentage with fallback
  Future<double> getDefaultServiceFeePercentage() async {
    try {
      final percentage = await getSetting('default_service_fee_percentage');
      return double.tryParse(percentage ?? '15.0') ?? 15.0; // Default 15%
    } catch (e) {
      return 15.0; // Fallback on error
    }
  }

  /// Fetch delivery fee with fallback
  Future<double> getDeliveryFee() async {
    try {
      print('🔍 AppSettingsService: Fetching delivery_fee setting...');
      final fee = await getSetting('delivery_fee');
      print('🔍 AppSettingsService: Raw fee value from DB: "$fee"');
      
      final parsedFee = double.tryParse(fee ?? '50.0') ?? 50.0;
      print('🔍 AppSettingsService: Parsed fee value: $parsedFee');
      
      return parsedFee;
    } catch (e) {
      print('❌ AppSettingsService: Error fetching delivery fee: $e');
      return 50.0; // Fallback on error
    }
  }
}

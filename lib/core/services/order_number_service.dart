import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to generate branded order numbers (C0001, C0002, etc.)
class OrderNumberService {
  final SupabaseClient _supabaseClient;

  OrderNumberService(this._supabaseClient);

  /// Generate next order number in format: C0001, C0002, etc.
  Future<String> generateOrderNumber() async {
    try {
      // Get the current counter value and increment it
      final response = await _supabaseClient.rpc('get_next_order_number');

      if (response is int) {
        // Format as C + 4-digit padded number
        final orderNumber = 'C${response.toString().padLeft(4, '0')}';
        print('📦 Generated order number: $orderNumber');
        return orderNumber;
      }

      // Fallback: If RPC doesn't exist, use timestamp-based
      return _generateFallbackOrderNumber();
    } catch (e) {
      print('❌ Error generating order number, using fallback: $e');
      return _generateFallbackOrderNumber();
    }
  }

  /// Fallback order number generator using timestamp
  /// Format: C + 8-digit timestamp-based number
  String _generateFallbackOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Use last 8 digits of timestamp
    final numberPart = (timestamp % 100000000).toString().padLeft(8, '0');
    final orderNumber = 'C$numberPart';
    print('📦 Generated fallback order number: $orderNumber');
    return orderNumber;
  }

  /// Validate order number format
  static bool isValidOrderNumber(String orderNumber) {
    // Should start with C and be followed by numbers
    final regex = RegExp(r'^C\d+$');
    return regex.hasMatch(orderNumber);
  }
}


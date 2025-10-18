import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

/// Service for handling location detection and validation
/// Uses Google's Geocoding API through the geocoding package
class LocationService {
  // Windhoek city center coordinates
  static const LatLng windhoekCenter = LatLng(-22.5609, 17.0658);
  
  // Maximum distance from city center (in kilometers)
  // This creates a ~25km radius around Windhoek center
  static const double maxDeliveryRadiusKm = 25.0;

  /// Check if location permissions are granted
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions from user
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check if location services are enabled on the device
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get the user's current location
  /// Throws exception if location cannot be obtained
  static Future<Position> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return position;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Check if a location is within Windhoek delivery range
  /// Uses two-layer validation:
  /// 1. Distance check (fast, offline)
  /// 2. Geocoding verification (accurate, requires internet)
  static Future<LocationValidationResult> isInWindhoekDeliveryArea(
    Position position,
  ) async {
    final userLocation = LatLng(position.latitude, position.longitude);

    // Layer 1: Quick distance check
    final distanceFromCenter = calculateDistance(userLocation, windhoekCenter);
    
    print('📍 User distance from WHK center: ${distanceFromCenter.toStringAsFixed(2)} km');

    // If user is way too far, reject immediately without API call
    if (distanceFromCenter > maxDeliveryRadiusKm) {
      return LocationValidationResult(
        isValid: false,
        distanceFromCenter: distanceFromCenter,
        cityName: null,
        message: 'You are ${distanceFromCenter.toStringAsFixed(1)}km from Windhoek. '
            'We currently only deliver within Windhoek.',
      );
    }

    // Layer 2: Geocoding verification for locations near the boundary
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        // If no placemark data, use distance check only
        return LocationValidationResult(
          isValid: distanceFromCenter <= maxDeliveryRadiusKm,
          distanceFromCenter: distanceFromCenter,
          cityName: null,
          message: distanceFromCenter <= maxDeliveryRadiusKm
              ? 'Location verified within delivery range'
              : 'Unable to verify exact location',
        );
      }

      final placemark = placemarks.first;
      final locality = placemark.locality?.toLowerCase() ?? '';
      final subAdmin = placemark.subAdministrativeArea?.toLowerCase() ?? '';
      final admin = placemark.administrativeArea?.toLowerCase() ?? '';

      print('📍 Geocoding result: '
          'locality=$locality, subAdmin=$subAdmin, admin=$admin');

      // Check if any of the location fields contain "windhoek"
      final isWindhoek = locality.contains('windhoek') ||
          subAdmin.contains('windhoek') ||
          admin.contains('windhoek');

      if (isWindhoek) {
        return LocationValidationResult(
          isValid: true,
          distanceFromCenter: distanceFromCenter,
          cityName: 'Windhoek',
          message: 'Location verified in Windhoek delivery area',
        );
      } else {
        return LocationValidationResult(
          isValid: false,
          distanceFromCenter: distanceFromCenter,
          cityName: locality.isNotEmpty ? locality : null,
          message: 'We currently only deliver in Windhoek. '
              'Your location appears to be in ${locality.isEmpty ? "an area outside our delivery zone" : locality}.',
        );
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      
      // Fallback to distance check if geocoding fails
      return LocationValidationResult(
        isValid: distanceFromCenter <= maxDeliveryRadiusKm,
        distanceFromCenter: distanceFromCenter,
        cityName: null,
        message: distanceFromCenter <= maxDeliveryRadiusKm
            ? 'Location verified (within ${maxDeliveryRadiusKm}km of Windhoek)'
            : 'Unable to verify your location. Please try again.',
      );
    }
  }

  /// Comprehensive check with permission handling
  /// Returns a detailed result with status and message
  static Future<LocationCheckResult> checkDeliveryEligibility() async {
    // Step 1: Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationCheckResult(
        status: LocationCheckStatus.serviceDisabled,
        message: 'Location services are disabled. Please enable location in your device settings.',
      );
    }

    // Step 2: Check permission
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationCheckResult(
          status: LocationCheckStatus.permissionDenied,
          message: 'Location permission is required to check delivery availability.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationCheckResult(
        status: LocationCheckStatus.permissionDeniedForever,
        message: 'Location permission is permanently denied. '
            'Please enable it in your device settings to check delivery availability.',
      );
    }

    // Step 3: Get current location
    Position? position;
    try {
      position = await getCurrentLocation();
    } catch (e) {
      return LocationCheckResult(
        status: LocationCheckStatus.error,
        message: 'Failed to get your location. Please check your GPS signal and try again.',
        error: e.toString(),
      );
    }

    // Step 4: Validate location
    try {
      final validationResult = await isInWindhoekDeliveryArea(position);
      
      if (validationResult.isValid) {
        return LocationCheckResult(
          status: LocationCheckStatus.success,
          message: validationResult.message,
          position: position,
          validationResult: validationResult,
        );
      } else {
        return LocationCheckResult(
          status: LocationCheckStatus.outsideDeliveryArea,
          message: validationResult.message,
          position: position,
          validationResult: validationResult,
        );
      }
    } catch (e) {
      return LocationCheckResult(
        status: LocationCheckStatus.error,
        message: 'Error validating location. Please try again.',
        error: e.toString(),
        position: position,
      );
    }
  }
}

/// Result of location validation
class LocationValidationResult {
  final bool isValid;
  final double distanceFromCenter;
  final String? cityName;
  final String message;

  LocationValidationResult({
    required this.isValid,
    required this.distanceFromCenter,
    required this.cityName,
    required this.message,
  });
}

/// Status of location check
enum LocationCheckStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  outsideDeliveryArea,
  error,
}

/// Complete result of delivery eligibility check
class LocationCheckResult {
  final LocationCheckStatus status;
  final String message;
  final Position? position;
  final LocationValidationResult? validationResult;
  final String? error;

  LocationCheckResult({
    required this.status,
    required this.message,
    this.position,
    this.validationResult,
    this.error,
  });

  bool get isSuccess => status == LocationCheckStatus.success;
  bool get canProceed => status == LocationCheckStatus.success;
}





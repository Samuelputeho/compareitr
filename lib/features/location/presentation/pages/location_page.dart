import 'package:compareitr/features/card/presentation/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps_flutter;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:compareitr/core/common/entities/cart_entity.dart';
import 'package:compareitr/core/services/location_service.dart';
import 'package:compareitr/core/services/app_settings_service.dart';
import 'package:compareitr/init_dependencies.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:io' show Platform;

class LocationSelectionPage extends StatefulWidget {
  final double totalPrice;
  final google_maps_flutter.LatLng townCenter;
  final List<CartEntity> cartItems;

  const LocationSelectionPage({
    super.key,
    required this.totalPrice,
    required this.townCenter,
    required this.cartItems,
  });

  @override
  _LocationSelectionPageState createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> 
    with SingleTickerProviderStateMixin {
  // Google Maps Controller
  google_maps_flutter.GoogleMapController? _mapController;
  
  // Variable to store the selected location
  google_maps_flutter.LatLng? _selectedLocation;
  
  // Set of markers to display on the map
  Set<google_maps_flutter.Marker> _markers = {};

  // Variables to store user inputs for street name and location
  String _streetName = '';
  String _locationName = '';
  String _houseNumber = '';

  // Variable to store the delivery fee (fetched from app_settings)
  double _deliveryFee = 50.0; // Default fallback
  double _deliveryFeePerShop = 50.0; // Default fallback
  int _numberOfShops = 1;
  
  // App settings service
  late AppSettingsService _appSettingsService;

  // Animation controller for button
  late AnimationController _controller;
  
  // Text controllers to avoid rebuilding issues
  late TextEditingController _streetController;
  late TextEditingController _locationController;
  late TextEditingController _houseController;

  @override
  void initState() {
    super.initState();
    print('🗺️ LocationSelectionPage initState started');
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _streetController = TextEditingController();
    _locationController = TextEditingController();
    _houseController = TextEditingController();
    
    // Initialize app settings service
    _appSettingsService = serviceLocator<AppSettingsService>();
    
    // Fetch delivery fee from app settings and calculate initial delivery fee
    _fetchDeliveryFeeAndCalculate();
    
    print('🗺️ LocationSelectionPage initState completed');
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController?.dispose();
    _streetController.dispose();
    _locationController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  // Function to handle location selection and populate fields
  void _onTap(google_maps_flutter.LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      
      // Update marker
      _markers = {
        google_maps_flutter.Marker(
          markerId: const google_maps_flutter.MarkerId('selected_location'),
          position: latLng,
          icon: google_maps_flutter.BitmapDescriptor.defaultMarkerWithHue(google_maps_flutter.BitmapDescriptor.hueRed),
          infoWindow: const google_maps_flutter.InfoWindow(title: 'Delivery Location'),
        ),
      };
    });

    // Fetch street name and location name using Google Geocoding
    await _fetchAddressFromCoordinates(latLng);

    // Calculate the delivery fee based on number of shops (N$50 per shop)
    _deliveryFee = _calculateDeliveryFee(latLng);
  }

  // Function to get current location and update map
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled. Please enable location services.');
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied. Please enable location permissions.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied. Please enable them in settings.');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Convert to Google Maps LatLng
      google_maps_flutter.LatLng currentLocation = google_maps_flutter.LatLng(
        position.latitude,
        position.longitude,
      );

      // Update the map to show current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          google_maps_flutter.CameraUpdate.newLatLngZoom(
            currentLocation,
            16.0, // Zoom level for current location
          ),
        );
      }

      // Update the selected location and marker
      setState(() {
        _selectedLocation = currentLocation;
        _markers = {
          google_maps_flutter.Marker(
            markerId: const google_maps_flutter.MarkerId('current_location'),
            position: currentLocation,
            icon: google_maps_flutter.BitmapDescriptor.defaultMarkerWithHue(google_maps_flutter.BitmapDescriptor.hueBlue),
            infoWindow: const google_maps_flutter.InfoWindow(title: 'Current Location'),
          ),
        };
      });

      // Fetch address for current location
      await _fetchAddressFromCoordinates(currentLocation);

      // Calculate delivery fee
      _deliveryFee = _calculateDeliveryFee(currentLocation);

      print('📍 Current location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showLocationError('Failed to get current location: $e');
      print('❌ Error getting current location: $e');
    }
  }

  // Function to show location error
  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Function to fetch address using Google Geocoding API
  Future<void> _fetchAddressFromCoordinates(google_maps_flutter.LatLng latLng) async {
    try {
      print('🔍 Fetching address for coordinates: ${latLng.latitude}, ${latLng.longitude}');
      
      // Add a small delay to ensure fresh geocoding request
      await Future.delayed(const Duration(milliseconds: 100));
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      print('🔍 Found ${placemarks.length} placemarks');
      
      if (placemarks.isNotEmpty) {
        // Try to find the best placemark with the most specific location info
        Placemark bestPlacemark = placemarks.first;
        
        for (var placemark in placemarks) {
          print('🔍 Checking placemark: ${placemark.subAdministrativeArea} - ${placemark.locality}');
          // Prefer placemarks with subAdministrativeArea (suburb/area)
          if (placemark.subAdministrativeArea?.isNotEmpty == true &&
              (bestPlacemark.subAdministrativeArea?.isEmpty != false)) {
            bestPlacemark = placemark;
            print('🔍 Found better placemark with subAdministrativeArea: ${placemark.subAdministrativeArea}');
          }
        }
        
        final placemark = bestPlacemark;
        
        setState(() {
          // Clear previous values first
          _streetName = '';
          _locationName = '';
          
          _streetName = placemark.street ?? placemark.thoroughfare ?? 'Unknown Street';
          
          // Try multiple fallback options for location name with better logic
          // Priority: subAdministrativeArea (suburb/area) > subLocality > locality > administrativeArea > country
          String locationName = '';
          if (placemark.subAdministrativeArea?.isNotEmpty == true) {
            locationName = placemark.subAdministrativeArea!;
          } else if (placemark.subLocality?.isNotEmpty == true) {
            locationName = placemark.subLocality!;
          } else if (placemark.locality?.isNotEmpty == true) {
            locationName = placemark.locality!;
          } else if (placemark.administrativeArea?.isNotEmpty == true) {
            locationName = placemark.administrativeArea!;
          } else if (placemark.country?.isNotEmpty == true) {
            locationName = placemark.country!;
          } else {
            locationName = 'Unknown Location';
          }
          
          _locationName = locationName;
          
          // Clear and update text controllers
          _streetController.clear();
          _locationController.clear();
          _streetController.text = _streetName;
          _locationController.text = _locationName;
          
          // Force text field to update by moving cursor to end
          _streetController.selection = TextSelection.fromPosition(
            TextPosition(offset: _streetController.text.length),
          );
          _locationController.selection = TextSelection.fromPosition(
            TextPosition(offset: _locationController.text.length),
          );
        });
        
        print('📍 Address found: $_streetName, $_locationName');
        print('📍 Placemark details:');
        print('   - Street: ${placemark.street}');
        print('   - Thoroughfare: ${placemark.thoroughfare}');
        print('   - SubLocality: ${placemark.subLocality}');
        print('   - Locality: ${placemark.locality}');
        print('   - SubAdministrativeArea: ${placemark.subAdministrativeArea}');
        print('   - AdministrativeArea: ${placemark.administrativeArea}');
        print('   - Country: ${placemark.country}');
        print('📍 Selected location name: "$_locationName"');
        print('📍 Text controller value: "${_locationController.text}"');
      }
    } catch (e) {
      print("❌ Error fetching address: $e");
      setState(() {
        _streetName = 'Unknown Street';
        _locationName = 'Unknown Location';
        _streetController.text = _streetName;
        _locationController.text = _locationName;
      });
    }
  }

  
  
  /// Fetch delivery fee from app settings and calculate initial delivery fee
  Future<void> _fetchDeliveryFeeAndCalculate() async {
    try {
      print('🔍 Attempting to fetch delivery fee from app settings...');
      
      // Fetch delivery fee from app settings
      _deliveryFeePerShop = await _appSettingsService.getDeliveryFee();
      print('🚚 Fetched delivery fee from app settings: N\$${_deliveryFeePerShop.toStringAsFixed(2)} per shop');
      
      // Calculate initial delivery fee based on number of unique shops in cart
      _calculateInitialDeliveryFee();
      
      // Update the UI after fetching the delivery fee
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Error fetching delivery fee from app settings: $e');
      print('🔄 Using default delivery fee: N\$50.00 per shop');
      _deliveryFeePerShop = 50.0; // Fallback to default
      _calculateInitialDeliveryFee();
      
      // Update the UI even with fallback
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Function to calculate initial delivery fee based on cart contents
  void _calculateInitialDeliveryFee() {
    // Count unique shops in the cart
    final uniqueShops = widget.cartItems.map((item) => item.shopName).toSet();
    _numberOfShops = uniqueShops.length;
    
    // Use the delivery fee per shop from app settings
    _deliveryFee = _deliveryFeePerShop * _numberOfShops;
    
    print('🛒 Initial delivery fee calculated: $_numberOfShops shops × N\$${_deliveryFeePerShop.toStringAsFixed(2)} = N\$${_deliveryFee.toStringAsFixed(2)}');
  }

  // Function to calculate the delivery fee (using dynamic fee from app settings)
  double _calculateDeliveryFee(google_maps_flutter.LatLng selectedLocation) {
    // Count unique shops in the cart
    final uniqueShops = widget.cartItems.map((item) => item.shopName).toSet();
    _numberOfShops = uniqueShops.length;
    
    // Use the delivery fee per shop from app settings
    return _deliveryFeePerShop * _numberOfShops;
  }

  /// Check if the selected delivery address is within Windhoek delivery area
  Future<void> _checkDeliveryAddressEligibility() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a delivery location first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text('Checking delivery address...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Use Google Geocoding API to check if delivery address is within Windhoek
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final cityName = placemark.locality?.toLowerCase() ?? '';
        final adminArea = placemark.administrativeArea?.toLowerCase() ?? '';
        final country = placemark.country?.toLowerCase() ?? '';
        
        // Check if the address is within Windhoek city boundaries
        final isInWindhoek = cityName.contains('windhoek') || 
                            adminArea.contains('khomas') ||
                            (country == 'namibia' && 
                             (cityName.contains('windhoek') || 
                              placemark.subLocality?.toLowerCase().contains('windhoek') == true));
        
        if (isInWindhoek) {
          // Delivery address is within Windhoek, proceed to payment
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  cartItems: widget.cartItems,
                  totalAmount: widget.totalPrice,
                  deliveryLocation: _selectedLocation!,
                  streetName: _streetName,
                  locationName: _locationName,
                  houseNumber: _houseNumber,
                  deliveryFee: _deliveryFee,
                ),
              ),
            );
          }
        } else {
          // Delivery address is outside Windhoek
          _showDeliveryAddressRestrictionDialog(_selectedLocation!, placemark);
        }
      } else {
        // No placemark data available, fallback to distance check
        final latlong2LatLng = latlong2.LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude);
        final distanceFromCenter = LocationService.calculateDistance(
          LocationService.windhoekCenter,
          latlong2LatLng,
        );
        
        if (distanceFromCenter <= LocationService.maxDeliveryRadiusKm) {
          // Within radius, proceed to payment
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  cartItems: widget.cartItems,
                  totalAmount: widget.totalPrice,
                  deliveryLocation: _selectedLocation!,
                  streetName: _streetName,
                  locationName: _locationName,
                  houseNumber: _houseNumber,
                  deliveryFee: _deliveryFee,
                ),
              ),
            );
          }
        } else {
          // Outside radius, show restriction
          _showDeliveryAddressRestrictionDialog(_selectedLocation!, null);
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      _showErrorDialog('Failed to check delivery address: ${e.toString()}');
    }
  }

  /// Show dialog when delivery address is outside Windhoek
  void _showDeliveryAddressRestrictionDialog(google_maps_flutter.LatLng selectedLocation, Placemark? placemark) async {
    // Calculate distance from Windhoek center for fallback information
    final latlong2LatLng = latlong2.LatLng(selectedLocation.latitude, selectedLocation.longitude);
    final distance = LocationService.calculateDistance(
      LocationService.windhoekCenter,
      latlong2LatLng,
    );

    String locationInfo = '';
    if (placemark != null) {
      // Show actual address information from Google Geocoding
      final cityName = placemark.locality ?? 'Unknown';
      final adminArea = placemark.administrativeArea ?? 'Unknown';
      final country = placemark.country ?? 'Unknown';
      locationInfo = 'Selected location: $cityName, $adminArea, $country';
    } else {
      // Fallback to distance information
      locationInfo = 'Distance from Windhoek center: ${distance.toStringAsFixed(1)} km';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('Outside Delivery Area'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We currently only deliver within Windhoek city boundaries.'),
            const SizedBox(height: 12),
            Text(
              locationInfo,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              '📍 Please select a delivery address within Windhoek to continue.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Tip: Try selecting a location closer to the city center.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  /// Show dialog for location errors
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text('Location Error'),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Apply map theme based on dark mode
  void _applyMapTheme(google_maps_flutter.GoogleMapController controller, bool isDarkMode) {
    if (isDarkMode) {
      controller.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#212121"}]
          },
          {
            "elementType": "labels.icon",
            "stylers": [{"visibility": "off"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#757575"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#212121"}]
          },
          {
            "featureType": "administrative",
            "elementType": "geometry",
            "stylers": [{"color": "#757575"}]
          },
          {
            "featureType": "administrative.country",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#9e9e9e"}]
          },
          {
            "featureType": "administrative.land_parcel",
            "stylers": [{"visibility": "off"}]
          },
          {
            "featureType": "administrative.locality",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#bdbdbd"}]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#757575"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry",
            "stylers": [{"color": "#181818"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#616161"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1b1b1b"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry.fill",
            "stylers": [{"color": "#2c2c2c"}]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#8a8a8a"}]
          },
          {
            "featureType": "road.arterial",
            "elementType": "geometry",
            "stylers": [{"color": "#373737"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [{"color": "#3c3c3c"}]
          },
          {
            "featureType": "road.highway.controlled_access",
            "elementType": "geometry",
            "stylers": [{"color": "#4e4e4e"}]
          },
          {
            "featureType": "road.local",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#616161"}]
          },
          {
            "featureType": "transit",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#757575"}]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [{"color": "#000000"}]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#3d3d3d"}]
          }
        ]
      ''');
    } else {
      controller.setMapStyle(null); // Reset to default light theme
    }
  }

  /// Build Google Map for both iOS and Android
  Widget _buildGoogleMap() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return google_maps_flutter.GoogleMap(
      initialCameraPosition: google_maps_flutter.CameraPosition(
        target: widget.townCenter,
        zoom: 13.0,
      ),
      onMapCreated: (google_maps_flutter.GoogleMapController controller) {
        _mapController = controller;
        print('🗺️ Google Map created successfully on ${Platform.isIOS ? 'iOS' : 'Android'}');
        
        // Apply dark theme if needed
        _applyMapTheme(controller, isDarkMode);
      },
      onTap: (latLng) {
        print('🗺️ Map tapped at: $latLng');
        _onTap(latLng);
      },
      markers: _markers,
      // Enable full functionality on both platforms now that iOS is fixed
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true, // Enable zoom controls
      mapToolbarEnabled: false,
      mapType: google_maps_flutter.MapType.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Reapply map theme when theme changes
    if (_mapController != null) {
      _applyMapTheme(_mapController!, isDarkMode);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Delivery Location"),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Display Google Map - Fixed for both iOS and Android
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Stack(
                children: [
                  // Use a custom scroll physics to prevent interference
                  NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      // Consume all scroll notifications from the map area
                      return true;
                    },
                    child: _buildGoogleMap(),
                  ),
                  // Current Location Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
            // Display total and delivery fee
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: N\$${widget.totalPrice.toStringAsFixed(2)}', // Use passed totalPrice
                    style: TextStyle(fontSize: 16, ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Delivery Fee: N\$${_deliveryFee.toStringAsFixed(2)} (N\$${_deliveryFeePerShop.toStringAsFixed(2)} × $_numberOfShops shop${_numberOfShops > 1 ? 's' : ''})', // Display per-shop delivery fee
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Overall Price: N\$${(widget.totalPrice + _deliveryFee).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Input for street name
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Street Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.streetview),
                    ),
                    controller: _streetController,
                    onChanged: (value) {
                      _streetName = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Input for location name
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Location Name (Suburb/Area)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    controller: _locationController,
                    onChanged: (value) {
                      _locationName = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Input for house number/complex number
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "House/Complex Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    controller: _houseController,
                    onChanged: (value) {
                      _houseNumber = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Button to confirm location
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return ElevatedButton(
                        onPressed: () async {
                          // Check if the selected delivery address is within Windhoek
                          await _checkDeliveryAddressEligibility();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTween(
                            begin: Colors.green,
                            end: Colors.black,
                          ).evaluate(_controller),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 5.0),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Confirm Location',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


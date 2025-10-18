# Location Validation Implementation Guide

## Overview
Automatic location validation has been implemented to ensure deliveries only occur within Windhoek. The system uses Google's Geocoding API for accurate location verification.

## How It Works

### User Flow
1. User adds items to cart
2. User presses "Buy Through App" button
3. System shows "Checking your location..." loading dialog
4. System automatically:
   - Requests location permission (if needed)
   - Gets GPS coordinates
   - Validates location against Windhoek boundaries
5. Based on result:
   - ✅ **In Windhoek** → Proceeds to location selection page
   - ❌ **Outside Windhoek** → Shows friendly restriction message
   - ⚠️ **Permission/Error** → Shows appropriate dialog

### Two-Layer Validation System

#### Layer 1: Distance Check (Fast)
- Calculates distance from Windhoek center (-22.5609, 17.0658)
- If > 25km → Immediate rejection (no API call)
- Saves on API quota for users far away

#### Layer 2: Geocoding Verification (Accurate)
- Uses Google Geocoding API (via `geocoding` package)
- Verifies actual city name matches "Windhoek"
- Only called for locations within 25km radius

## Files Modified/Created

### New Files
- **`lib/core/services/location_service.dart`**
  - `LocationService` class with static methods
  - `checkDeliveryEligibility()` - Main entry point
  - `isInWindhoekDeliveryArea()` - Validation logic
  - Comprehensive error handling

### Modified Files
- **`lib/features/cart/presentation/pages/cart_page.dart`**
  - Added `_checkLocationAndProceed()` method
  - Added 5 dialog methods for different scenarios
  - Updated "Buy Through App" button to check location first

## Configuration

### Windhoek Delivery Settings
Located in `location_service.dart`:

```dart
// City center coordinates
static const LatLng windhoekCenter = LatLng(-22.5609, 17.0658);

// Maximum delivery radius (in kilometers)
static const double maxDeliveryRadiusKm = 25.0;
```

**To adjust delivery area:**
- Increase/decrease `maxDeliveryRadiusKm` value
- 25km covers most of Windhoek suburbs

## Permissions

### Android
Already configured in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS
Already configured in `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to check delivery availability</string>
```

## Google API Setup

### Required APIs
1. **Geocoding API** - For address verification
   - Already used by `geocoding` package
   - Ensure it's enabled in Google Cloud Console

### Current Package
The `geocoding: ^3.0.0` package uses Google's Geocoding API by default.

**Check your API key:**
- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/AppDelegate.swift`

### API Costs (as of 2024)
- **Free tier**: 40,000 requests/month
- **After free tier**: $5 per 1,000 requests
- **Our optimization**: Distance check reduces API calls by ~90%

**Example calculation:**
- 1,000 users/day checking location
- With distance filter: ~3,000 API calls/month
- Well within free tier ✅

## User Experience Scenarios

### Scenario 1: User in Windhoek
```
1. Press "Buy Through App"
2. Loading dialog: "Checking your location..."
3. Permission granted → GPS acquired
4. Validation: ✅ Within 5km of center
5. Geocoding confirms: "Windhoek"
6. → Navigate to location selection page
```

### Scenario 2: User in Swakopmund (350km away)
```
1. Press "Buy Through App"
2. Loading dialog: "Checking your location..."
3. Permission granted → GPS acquired
4. Distance check: 350km > 25km
5. Immediate rejection (no API call)
6. Dialog: "You are 350km from Windhoek..."
7. User sees friendly message about future expansion
```

### Scenario 3: Location Permission Denied
```
1. Press "Buy Through App"
2. System requests permission
3. User denies
4. Dialog: "Location Permission Required"
5. Explains why needed
6. Options: Cancel or try again
```

### Scenario 4: GPS/Location Disabled
```
1. Press "Buy Through App"
2. System detects location services off
3. Dialog: "Location Services Disabled"
4. Options: Cancel or "Open Settings"
5. If "Open Settings" → Opens device location settings
```

## Testing Checklist

### Local Testing
- [x] User in Windhoek → Should proceed
- [ ] User outside Windhoek → Should be blocked
- [ ] Location permission denied → Should show dialog
- [ ] Location permission permanently denied → Should offer settings
- [ ] GPS disabled → Should offer to enable
- [ ] Network error during geocoding → Should fallback to distance check
- [ ] Slow GPS (15s timeout) → Should show error

### Emulator Testing
Use Android Studio's emulator location features:
1. Extended Controls → Location
2. Set coordinates to:
   - **Windhoek**: -22.5609, 17.0658 (should allow)
   - **Swakopmund**: -22.6760, 14.5272 (should block)
   - **Oshakati**: -17.7839, 15.6963 (should block)

## Future Enhancements

### When Expanding to New Cities

**Option 1: Database-driven (Recommended)**
Create `delivery_areas` table in Supabase:
```sql
CREATE TABLE delivery_areas (
  id UUID PRIMARY KEY,
  city_name TEXT,
  center_lat DECIMAL,
  center_lng DECIMAL,
  radius_km DECIMAL,
  is_active BOOLEAN
);
```

Fetch active areas and check against all.

**Option 2: Multiple Cities in Code**
```dart
static const deliveryAreas = [
  {'name': 'Windhoek', 'center': LatLng(-22.5609, 17.0658), 'radius': 25.0},
  {'name': 'Swakopmund', 'center': LatLng(-22.6760, 14.5272), 'radius': 15.0},
];
```

### Notification System
When user outside delivery area:
- Store their location/city
- Send push notification when you expand to their area
- Build anticipation and user base

## Troubleshooting

### Issue: "Location permission permanently denied"
**Solution:** User must manually enable in device settings
- Android: Settings → Apps → CompareItr → Permissions → Location
- iOS: Settings → CompareItr → Location

### Issue: Geocoding always fails
**Possible causes:**
1. No internet connection → Falls back to distance check
2. API key not set up → Check Google Cloud Console
3. API key quota exceeded → Check usage in console
4. API not enabled → Enable Geocoding API

### Issue: GPS timeout
**Causes:**
- User indoors
- GPS signal poor
- Device GPS disabled

**Solution:** System shows error, user can retry

### Issue: False negatives (Windhoek user blocked)
**Causes:**
- GPS inaccuracy
- Geocoding returns incorrect data

**Debug:**
- Check console logs: `📍 User distance from WHK center: X km`
- Check console logs: `📍 Geocoding result: locality=...`
- Adjust `maxDeliveryRadiusKm` if needed

## Monitoring & Analytics

### Recommended Tracking
Add analytics to track:
1. How many users checked out
2. How many were blocked (by distance)
3. Geographic distribution of blocked users
4. Most common rejection cities

This helps plan expansion strategy!

### Implementation Example
```dart
// In _checkLocationAndProceed
if (result.status == LocationCheckStatus.outsideDeliveryArea) {
  // Log to analytics
  analytics.logEvent('checkout_blocked_by_location', {
    'distance_km': result.validationResult?.distanceFromCenter,
    'city': result.validationResult?.cityName,
  });
}
```

## Support

For issues or questions:
1. Check console logs (look for 📍 emoji logs)
2. Verify API key configuration
3. Test with emulator location
4. Check Google Cloud Console for API errors













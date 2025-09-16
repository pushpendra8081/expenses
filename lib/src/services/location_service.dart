import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Location result model
class LocationResult {
  final bool isSuccess;
  final Position? location;
  final String? error;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? address;

  const LocationResult({
    required this.isSuccess,
    this.location,
    this.error,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.address,
  });

  @override
  String toString() {
    return 'LocationResult(isSuccess: $isSuccess, lat: $latitude, lng: $longitude, accuracy: $accuracy, timestamp: $timestamp)';
  }
}

// Location permission status
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  restricted,
  unknown,
}

class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Minimum distance (in meters) to trigger location update
  );

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current location permission status
  static Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  // Request location permission
  static Future<LocationPermissionStatus> requestLocationPermission() async {
    // First check if location services are enabled
    if (!await isLocationServiceEnabled()) {
      throw LocationServiceException('Location services are disabled.');
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }

  // Get current location
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // Check and request permissions
      final permissionStatus = await requestLocationPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        return LocationResult(
          isSuccess: false,
          location: null,
          error: 'Location permission not granted: $permissionStatus',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
        );
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationResult(
        isSuccess: true,
        location: position,
        error: null,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } on LocationServiceDisabledException {
      return LocationResult(
        isSuccess: false,
        location: null,
        error: 'Location services are disabled.',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
    } on PermissionDeniedException {
      return LocationResult(
        isSuccess: false,
        location: null,
        error: 'Location permission denied.',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        location: null,
        error: 'Failed to get current location: $e',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
    }
  }

  // Get current location with timeout
  static Future<LocationResult> getCurrentLocationWithTimeout({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await getCurrentLocation().timeout(timeout);
    } on TimeoutException {
      throw LocationTimeoutException('Location request timed out after ${timeout.inSeconds} seconds.');
    }
  }

  // Get last known location
  static Future<LocationResult?> getLastKnownLocation() async {
    try {
      final permissionStatus = await getLocationPermissionStatus();
      if (permissionStatus != LocationPermissionStatus.granted) {
        return null;
      }

      final Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationResult(
        isSuccess: true,
        location: position,
        error: null,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  static double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Get location stream for real-time updates
  static Stream<LocationResult> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).map((position) => LocationResult(
      isSuccess: true,
      location: position,
      error: null,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
    ));
  }

  // Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Check if coordinates are valid
  static bool isValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  // Get location with retry mechanism
  static Future<LocationResult> getCurrentLocationWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await getCurrentLocation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(retryDelay);
      }
    }
    
    throw LocationException('Failed to get location after $maxRetries attempts');
  }

  // Get approximate location (lower accuracy, faster)
  static Future<LocationResult> getApproximateLocation() async {
    try {
      final permissionStatus = await requestLocationPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        return LocationResult(
          isSuccess: false,
          location: null,
          error: 'Location permission not granted: $permissionStatus',
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
        );
      }

      const lowAccuracySettings = LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100,
      );

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      return LocationResult(
        isSuccess: true,
        location: position,
        error: null,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp ?? DateTime.now(),
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        location: null,
        error: 'Failed to get approximate location: $e',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
    }
  }

  // Check if location data is available
  static bool hasLocation(double? latitude, double? longitude) {
    return isValidCoordinates(latitude, longitude);
  }
}

// Custom exceptions
class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}

class LocationPermissionException extends LocationException {
  LocationPermissionException(String message) : super(message);
}

class LocationServiceException extends LocationException {
  LocationServiceException(String message) : super(message);
}

class LocationTimeoutException extends LocationException {
  LocationTimeoutException(String message) : super(message);
}
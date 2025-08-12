import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  bool _isInitialized = false;

  LocationProvider() {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _locationService.initialize();
    _isInitialized = true;
    notifyListeners();
  }

  void setCountry(String countryCode) {
    _locationService.setCountry(countryCode);
    notifyListeners();
  }

  String formatPrice(double price) {
    return _locationService.formatPrice(price);
  }

  String get currencyCode => _locationService.currencyCode;
  String get countryCode => _locationService.countryCode;
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // For ChangeNotifier

class LocationService extends ChangeNotifier {
  static const String _ipApiUrl = 'http://ip-api.com/json';
  static const String _exchangeRateApiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';
  static const String _cacheKeyRate = 'usd_to_inr_rate';
  static const String _cacheKeyTimestamp = 'rate_timestamp';

  String? _countryCode;
  String? _currencyCode;
  double _exchangeRateINR = 83.0; // Default fallback rate

  LocationService() {
    _initializeSync();
    initialize();
  }

  void _initializeSync() {
    // Smart defaults based on device locale/timezone for immediate correct currency
    try {
      // Try to detect India from device timezone or locale
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      
      // Check if device timezone suggests India (IST)
      if (timeZoneName.contains('IST') || 
          timeZoneName.contains('Asia/Kolkata') ||
          timeZoneName.contains('Asia/Calcutta') ||
          now.timeZoneOffset.inHours == 5 && now.timeZoneOffset.inMinutes == 30) {
        // Likely Indian user - start with INR
        _countryCode = 'IN';
        _currencyCode = 'INR';
        _exchangeRateINR = 83.0;
        print('Detected Indian timezone, starting with INR');
      } else {
        // Default to USD for other timezones
        _countryCode = 'US';
        _currencyCode = 'USD';
        _exchangeRateINR = 83.0;
        print('Non-Indian timezone detected, starting with USD');
      }
    } catch (e) {
      // Fallback to USD if timezone detection fails
      _countryCode = 'US';
      _currencyCode = 'USD';
      _exchangeRateINR = 83.0;
      print('Timezone detection failed, using USD default');
    }
  }

  Future<void> initialize() async {
    try {
      // Load saved preferences first
      final prefs = await SharedPreferences.getInstance();
      final savedCountry = prefs.getString('user_country');
      final cachedRate = prefs.getDouble(_cacheKeyRate);
      
      if (savedCountry != null) {
        // Use saved preference
        _countryCode = savedCountry;
        _currencyCode = savedCountry == 'IN' ? 'INR' : 'USD';
        if (cachedRate != null && _currencyCode == 'INR') {
          _exchangeRateINR = cachedRate;
        }
        notifyListeners(); // Notify immediately with saved preferences
      }

      // Get location from IP for both web and mobile platforms if no saved preference
      if (savedCountry == null) {
        try {
          final locationResponse = await http.get(Uri.parse(_ipApiUrl)).timeout(Duration(seconds: 5));
          if (locationResponse.statusCode == 200) {
            final locationData = json.decode(locationResponse.body);
            final detectedCountry = locationData['countryCode'];

            // Only support US and IN
            if (detectedCountry == 'IN') {
              _countryCode = 'IN';
              _currencyCode = 'INR';
            } else {
              _countryCode = 'US';
              _currencyCode = 'USD';
            }
            // Save detected country
            await prefs.setString('user_country', _countryCode!);
            print('Detected country: $_countryCode, Currency: $_currencyCode');
          } else {
            // If location detection fails, keep USD default
            print('Location detection failed, using USD default');
          }
        } catch (e) {
          print('Location detection error: $e, using USD default');
          // Keep USD default if location detection fails
        }
      }

      // Fetch exchange rate for INR if needed
      if (_currencyCode == 'INR') {
        await _fetchAndCacheExchangeRate();
      }
    } catch (e) {
      print('Error initializing location service: $e');
      // Keep current values or use defaults
      if (_countryCode == null) {
        _countryCode = 'IN';
        _currencyCode = 'INR';
        _exchangeRateINR = 83.0;
      }
    }
    notifyListeners();
  }

  Future<void> _fetchAndCacheExchangeRate() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRate = prefs.getDouble(_cacheKeyRate);
    final cachedTimestamp = prefs.getInt(_cacheKeyTimestamp);

    // Check if cached rate is valid (less than 24 hours old)
    const cacheDuration = Duration(hours: 24);
    if (cachedRate != null &&
        cachedTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - cachedTimestamp <
            cacheDuration.inMilliseconds) {
      _exchangeRateINR = cachedRate;
      return;
    }

    try {
      final response = await http.get(Uri.parse(_exchangeRateApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRateINR = data['rates']['INR'] ?? 83.0;
        // Cache the rate and timestamp
        await prefs.setDouble(_cacheKeyRate, _exchangeRateINR);
        await prefs.setInt(
            _cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      } else {
        _exchangeRateINR = 83.0; // Fallback rate
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
      _exchangeRateINR = 83.0; // Fallback rate
    }
    notifyListeners();
  }

  void setCountry(String countryCode) async {
    _countryCode = countryCode;
    _currencyCode = countryCode == 'IN' ? 'INR' : 'USD';
    
    // Save preference immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_country', countryCode);
    } catch (e) {
      print('Error saving country preference: $e');
    }
    
    if (_currencyCode == 'INR') {
      _fetchAndCacheExchangeRate();
    } else {
      _exchangeRateINR = 83.0; // Reset to default for non-INR
    }
    notifyListeners();
  }

  String formatPrice(double priceInUSD) {
    if (_currencyCode == 'INR') {
      final priceInINR = priceInUSD * _exchangeRateINR;
      return NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 2,
        locale: 'hi_IN',
      ).format(priceInINR);
    } else {
      // USD price
      return NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
        locale: 'en_US',
      ).format(priceInUSD);
    }
  }

  String get currencyCode => _currencyCode ?? 'USD';
  String get countryCode => _countryCode ?? 'US';
  double get exchangeRateINR => _exchangeRateINR;
}
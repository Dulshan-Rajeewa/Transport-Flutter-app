import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaultSettings;
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to load from Firestore first
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final settingsDoc = await firestore.collection('app_settings').doc('main_settings').get();
      
      if (settingsDoc.exists && settingsDoc.data() != null) {
        _settings = AppSettings.fromJson(settingsDoc.data()!);
        
        // Also save to SharedPreferences as backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appSettings', jsonEncode(_settings.toJson()));
      } else {
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final storedSettings = prefs.getString('appSettings');

        if (storedSettings != null) {
          final parsedSettings = jsonDecode(storedSettings);
          _settings = AppSettings.fromJson(parsedSettings);
        } else {
          _settings = AppSettings.defaultSettings;
        }
        
        // Save default settings to Firestore
        await firestore.collection('app_settings').doc('main_settings').set(_settings.toJson());
      }

      // Load custom routes from Firestore
      await _loadRoutesFromFirestore();
    } catch (error) {
      debugPrint('Error loading settings: $error');
      _settings = AppSettings.defaultSettings;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRoutesFromFirestore() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('routes').get();
      
      final customRoutes = querySnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // Combine default routes with custom routes
      final defaultRoutes = AppSettings.defaultSettings.defaultRoutes;
      final allRoutes = [...defaultRoutes];
      
      // Add custom routes before 'Custom Route' option
      final customRouteIndex = allRoutes.indexOf('Custom Route');
      if (customRouteIndex != -1) {
        allRoutes.removeAt(customRouteIndex);
        allRoutes.addAll(customRoutes);
        allRoutes.add('Custom Route');
      } else {
        allRoutes.addAll(customRoutes);
      }

      // Update settings with combined routes
      _settings = _settings.copyWith(defaultRoutes: allRoutes);
    } catch (error) {
      debugPrint('Error loading routes from Firestore: $error');
    }
  }

  Future<void> addCustomRoute(String routeName) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Check if route already exists
      final existingRoutes = await firestore.collection('routes')
          .where('name', isEqualTo: routeName)
          .get();
      
      if (existingRoutes.docs.isEmpty) {
        // Add new route to Firestore
        await firestore.collection('routes').add({
          'name': routeName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Reload routes
        await _loadRoutesFromFirestore();
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error adding custom route: $error');
      rethrow;
    }
  }

  Future<void> updateRoute(String oldRouteName, String newRouteName) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Find the route document
      final routeQuery = await firestore.collection('routes')
          .where('name', isEqualTo: oldRouteName)
          .get();
      
      if (routeQuery.docs.isNotEmpty) {
        // Update the route name
        await routeQuery.docs.first.reference.update({
          'name': newRouteName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Reload routes
        await _loadRoutesFromFirestore();
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error updating route: $error');
      rethrow;
    }
  }

  Future<void> deleteRoute(String routeName) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Find and delete the route document
      final routeQuery = await firestore.collection('routes')
          .where('name', isEqualTo: routeName)
          .get();
      
      if (routeQuery.docs.isNotEmpty) {
        await routeQuery.docs.first.reference.delete();
        
        // Reload routes
        await _loadRoutesFromFirestore();
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Error deleting route: $error');
      rethrow;
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      _settings = newSettings;
      notifyListeners();

      // Save to Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('app_settings').doc('main_settings').set(_settings.toJson());
      
      // Also save to SharedPreferences as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appSettings', jsonEncode(_settings.toJson()));
    } catch (error) {
      debugPrint('Error saving settings: $error');
      rethrow;
    }
  }

  Future<void> updatePartialSettings({
    double? pricePerKm,
    double? driverPaymentPerKm,
    double? fuelCostPerKm,
    List<String>? defaultRoutes,
    String? currency,
  }) async {
    final updatedSettings = _settings.copyWith(
      pricePerKm: pricePerKm,
      driverPaymentPerKm: driverPaymentPerKm,
      fuelCostPerKm: fuelCostPerKm,
      defaultRoutes: defaultRoutes,
      currency: currency,
    );
    await updateSettings(updatedSettings);
  }
}

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/app_logger.dart';
import '../error/app_exception.dart';

/// A service for local storage operations
class LocalStorageService {
  late final SharedPreferences _preferences;
  late final HiveInterface _hive;
  late final AppLogger _logger;
  
  /// Default box name for Hive
  static const String defaultBoxName = 'app_data';
  
  /// Create a new [LocalStorageService] instance
  LocalStorageService({
    required SharedPreferences sharedPreferences,
    AppLogger? logger,
  }) : _preferences = sharedPreferences, 
       _logger = logger ?? AppLogger(),
       _hive = Hive;
  
  /// Initializes the service
  Future<void> initialize() async {
    try {
      _logger.i('LocalStorageService: Initializing...');
      // Initialize Hive here if needed
      // await Hive.initFlutter();
      
      // Register adapters here
      
      _logger.i('LocalStorageService: Initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Failed to initialize', e, stackTrace);
      throw AppException.initialization(
        message: 'Failed to initialize storage',
        cause: e,
      );
    }
  }
  
  /// Save a string value
  Future<bool> saveString(String key, String value) async {
    try {
      final result = await _preferences.setString(key, value);
      _logger.d('LocalStorageService: Saved string for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving string for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save string value',
        cause: e,
      );
    }
  }
  
  /// Retrieve a string value
  String? getString(String key) {
    try {
      final value = _preferences.getString(key);
      _logger.d('LocalStorageService: Retrieved string for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving string for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve string value',
        cause: e,
      );
    }
  }
  
  /// Save a boolean value
  Future<bool> saveBool(String key, bool value) async {
    try {
      final result = await _preferences.setBool(key, value);
      _logger.d('LocalStorageService: Saved boolean for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving boolean for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save boolean value',
        cause: e,
      );
    }
  }
  
  /// Retrieve a boolean value
  bool? getBool(String key) {
    try {
      final value = _preferences.getBool(key);
      _logger.d('LocalStorageService: Retrieved boolean for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving boolean for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve boolean value',
        cause: e,
      );
    }
  }
  
  /// Save an integer value
  Future<bool> saveInt(String key, int value) async {
    try {
      final result = await _preferences.setInt(key, value);
      _logger.d('LocalStorageService: Saved integer for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving integer for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save integer value',
        cause: e,
      );
    }
  }
  
  /// Retrieve an integer value
  int? getInt(String key) {
    try {
      final value = _preferences.getInt(key);
      _logger.d('LocalStorageService: Retrieved integer for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving integer for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve integer value',
        cause: e,
      );
    }
  }
  
  /// Save a double value
  Future<bool> saveDouble(String key, double value) async {
    try {
      final result = await _preferences.setDouble(key, value);
      _logger.d('LocalStorageService: Saved double for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving double for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save double value',
        cause: e,
      );
    }
  }
  
  /// Retrieve a double value
  double? getDouble(String key) {
    try {
      final value = _preferences.getDouble(key);
      _logger.d('LocalStorageService: Retrieved double for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving double for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve double value',
        cause: e,
      );
    }
  }
  
  /// Save a string list
  Future<bool> saveStringList(String key, List<String> value) async {
    try {
      final result = await _preferences.setStringList(key, value);
      _logger.d('LocalStorageService: Saved string list for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving string list for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save string list',
        cause: e,
      );
    }
  }
  
  /// Retrieve a string list
  List<String>? getStringList(String key) {
    try {
      final value = _preferences.getStringList(key);
      _logger.d('LocalStorageService: Retrieved string list for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving string list for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve string list',
        cause: e,
      );
    }
  }
  
  /// Save an object by serializing it to JSON
  Future<bool> saveObject<T>(String key, T value) async {
    try {
      final jsonString = json.encode(value);
      final result = await _preferences.setString(key, jsonString);
      _logger.d('LocalStorageService: Saved object for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving object for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save object',
        cause: e,
      );
    }
  }
  
  /// Retrieve an object by deserializing it from JSON
  T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    try {
      final jsonString = _preferences.getString(key);
      if (jsonString == null) return null;
      
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final value = fromJson(jsonMap);
      _logger.d('LocalStorageService: Retrieved object for key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving object for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve object',
        cause: e,
      );
    }
  }
  
  /// Save a string value
  Future<bool> setString(String key, String value) async {
    try {
      final result = await _preferences.setString(key, value);
      _logger.d('LocalStorageService: Set string for key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error setting string for key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to set string value',
        cause: e,
      );
    }
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      final result = await _preferences.remove(key);
      _logger.d('LocalStorageService: Removed key "$key"');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error removing key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to remove key',
        cause: e,
      );
    }
  }
  
  /// Clear all values
  Future<bool> clear() async {
    try {
      final result = await _preferences.clear();
      _logger.d('LocalStorageService: Cleared all values');
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error clearing values', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to clear values',
        cause: e,
      );
    }
  }
  
  /// Check if a key exists
  bool containsKey(String key) {
    try {
      final result = _preferences.containsKey(key);
      return result;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error checking if key "$key" exists', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to check if key exists',
        cause: e,
      );
    }
  }
  
  // Hive methods
  
  /// Get a Hive box
  Box<T> getBox<T>(String boxName) {
    try {
      if (!_hive.isBoxOpen(boxName)) {
        throw AppException.cache(
          message: 'Box "$boxName" is not open',
        );
      }
      return _hive.box<T>(boxName);
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error getting box "$boxName"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to get box',
        cause: e,
      );
    }
  }
  
  /// Open a Hive box
  Future<Box<T>> openBox<T>(String boxName) async {
    try {
      final box = await _hive.openBox<T>(boxName);
      _logger.d('LocalStorageService: Opened box "$boxName"');
      return box;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error opening box "$boxName"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to open box',
        cause: e,
      );
    }
  }
  
  /// Close a Hive box
  Future<void> closeBox(String boxName) async {
    try {
      if (_hive.isBoxOpen(boxName)) {
        final box = _hive.box(boxName);
        await box.close();
        _logger.d('LocalStorageService: Closed box "$boxName"');
      }
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error closing box "$boxName"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to close box',
        cause: e,
      );
    }
  }
  
  /// Save a value to a Hive box
  Future<void> saveToBox<T>({
    required String boxName,
    required String key,
    required T value,
  }) async {
    try {
      final box = getBox<T>(boxName);
      await box.put(key, value);
      _logger.d('LocalStorageService: Saved value to box "$boxName" with key "$key"');
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error saving to box "$boxName" with key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to save to box',
        cause: e,
      );
    }
  }
  
  /// Get a value from a Hive box
  T? getFromBox<T>({
    required String boxName,
    required String key,
  }) {
    try {
      final box = getBox<T>(boxName);
      final value = box.get(key);
      _logger.d('LocalStorageService: Retrieved value from box "$boxName" with key "$key"');
      return value;
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error retrieving from box "$boxName" with key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to retrieve from box',
        cause: e,
      );
    }
  }
  
  /// Delete a value from a Hive box
  Future<void> deleteFromBox({
    required String boxName,
    required String key,
  }) async {
    try {
      final box = getBox(boxName);
      await box.delete(key);
      _logger.d('LocalStorageService: Deleted value from box "$boxName" with key "$key"');
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error deleting from box "$boxName" with key "$key"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to delete from box',
        cause: e,
      );
    }
  }
  
  /// Clear all values from a Hive box
  Future<void> clearBox(String boxName) async {
    try {
      final box = getBox(boxName);
      await box.clear();
      _logger.d('LocalStorageService: Cleared all values from box "$boxName"');
    } catch (e, stackTrace) {
      _logger.e('LocalStorageService: Error clearing box "$boxName"', e, stackTrace);
      throw AppException.cache(
        message: 'Failed to clear box',
        cause: e,
      );
    }
  }
}

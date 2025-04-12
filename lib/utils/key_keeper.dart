import 'package:flutter/material.dart';

/// A utility class that manages GlobalKeys to prevent duplication errors
class KeyKeeper {
  // Private constructor to prevent instantiation
  KeyKeeper._();
  
  // Static map to store and reuse keys
  static final Map<String, GlobalKey> _keys = {};
  
  /// Get a GlobalKey for a specific identifier, creating one if it doesn't exist
  static GlobalKey getKey(String id) {
    if (!_keys.containsKey(id)) {
      _keys[id] = GlobalKey();
    }
    return _keys[id]!;
  }
  
  /// Reset all keys (use carefully, typically only in testing)
  static void resetKeys() {
    _keys.clear();
  }
}
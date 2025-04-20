import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  String _apiKey = 'AIzaSyBAe6uVh_CdRB8-Oz3pjVPGLr6r4H6SWEs'; // Your default API key
  bool _isConnectedToLG = false;
  String _lgIP = '192.168.1.100';
  int _lgPort = 8080;

  String get apiKey => _apiKey;
  bool get isConnectedToLG => _isConnectedToLG;
  String get lgIP => _lgIP;
  int get lgPort => _lgPort;

  AppState() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('apiKey') ?? _apiKey;
    _lgIP = prefs.getString('lgIP') ?? _lgIP;
    _lgPort = prefs.getInt('lgPort') ?? _lgPort;
    notifyListeners();
  }

  Future<void> setApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', value);
    _apiKey = value;
    notifyListeners();
  }

  Future<void> setLgIP(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lgIP', value);
    _lgIP = value;
    notifyListeners();
  }

  Future<void> setLgPort(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lgPort', value);
    _lgPort = value;
    notifyListeners();
  }

  Future<void> connectToLG() async {
    // Here you would implement actual connection logic
    // For now we'll just simulate a successful connection
    _isConnectedToLG = true;
    notifyListeners();
  }

  Future<void> disconnectFromLG() async {
    // Here you would implement actual disconnection logic
    _isConnectedToLG = false;
    notifyListeners();
  }

  final systemPrompt = '''
You are a KML generator. Only return valid XML output that starts with <kml> and ends with </kml>. 
No explanation, no markdown, no commentary.

Instructions:
- Based on the user's query, find 3-7 relevant historical or cultural locations.
- For each, generate a <Placemark> with:
  - <name>: location name
  - <description>: short historical or cultural summary
  - <Point><coordinates>: longitude,latitude,0 (with decimal precision)

Wrap everything in a <kml><Document>...</Document></kml> structure.
Ensure output is valid KML syntax.
''';
}
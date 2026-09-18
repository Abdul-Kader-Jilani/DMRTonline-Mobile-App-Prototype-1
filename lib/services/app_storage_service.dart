import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/profile/models/user_profile_model.dart';
import '../shared/models/ticket_model.dart';

/// Service for persisting app state, tickets, history, profile, and auth locally
class AppStorageService {
  static const String _keyUserProfile = 'dmrt_user_profile';
  static const String _keyTickets = 'dmrt_active_tickets';
  static const String _keyHistory = 'dmrt_ticket_history';
  static const String _keyIsAuthenticated = 'dmrt_is_authenticated';
  static const String _keyAuthPhone = 'dmrt_auth_phone';

  static AppStorageService? _instance;
  final SharedPreferences _prefs;

  AppStorageService._(this._prefs);

  static Future<AppStorageService> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = AppStorageService._(prefs);
    return _instance!;
  }

  static void resetInstanceForTesting() {
    _instance = null;
  }

  // --- User Profile ---
  Future<bool> saveUserProfile(UserProfileModel profile) async {
    final jsonString = jsonEncode(profile.toJson());
    return await _prefs.setString(_keyUserProfile, jsonString);
  }

  UserProfileModel? loadUserProfile() {
    final jsonString = _prefs.getString(_keyUserProfile);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfileModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Active Tickets ---
  Future<bool> saveTickets(List<TicketModel> tickets) async {
    final listMaps = tickets.map((t) => t.toJson()).toList();
    final jsonString = jsonEncode(listMaps);
    return await _prefs.setString(_keyTickets, jsonString);
  }

  List<TicketModel>? loadTickets() {
    final jsonString = _prefs.getString(_keyTickets);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Ticket History ---
  Future<bool> saveHistory(List<TicketModel> history) async {
    final listMaps = history.map((t) => t.toJson()).toList();
    final jsonString = jsonEncode(listMaps);
    return await _prefs.setString(_keyHistory, jsonString);
  }

  List<TicketModel>? loadHistory() {
    final jsonString = _prefs.getString(_keyHistory);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Auth State ---
  Future<bool> saveAuthState({
    required bool isAuthenticated,
    String? phoneNumber,
  }) async {
    await _prefs.setBool(_keyIsAuthenticated, isAuthenticated);
    if (phoneNumber != null) {
      await _prefs.setString(_keyAuthPhone, phoneNumber);
    } else {
      await _prefs.remove(_keyAuthPhone);
    }
    return true;
  }

  bool loadIsAuthenticated() {
    return _prefs.getBool(_keyIsAuthenticated) ?? true;
  }

  String? loadAuthPhone() {
    return _prefs.getString(_keyAuthPhone);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

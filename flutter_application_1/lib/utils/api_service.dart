import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════
//  API SERVICE — ChargeGuard Backend
// ════════════════════════════════════════
class ApiService {
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  // Use localhost for iOS simulator
  // Use your computer's IP (e.g. 192.168.x.x) for physical devices
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Singleton
  static final ApiService instance = ApiService._();
  ApiService._();

  // JWT token (set after login)
  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  // ── Headers ─────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Helper ───────────────────────────────────────────────
  Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return {'success': true, 'data': body};
    } else {
      return {'success': false, 'message': body['message'] ?? 'Something went wrong'};
    }
  }

  // ════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════

  // Register
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String role   = 'driver',
    String region = 'Palestine',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'firstName': firstName, 'lastName': lastName,
          'email': email, 'password': password,
          'role': role, 'region': region,
        }),
      );
      final result = await _handleResponse(res);
      if (result['success']) {
        _token = result['data']['token'];
        UserSession.instance.setUser(result['data']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Is it running?'};
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final result = await _handleResponse(res);
      if (result['success']) {
        _token = result['data']['token'];
        UserSession.instance.setUser(result['data']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Is it running?'};
    }
  }

  // Logout
  void logout() {
    _token = null;
    UserSession.instance.clear();
  }

  // ════════════════════════════════════════
  //  USERS
  // ════════════════════════════════════════

  // Get profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/profile'), headers: _headers);
      final result = await _handleResponse(res);
      if (result['success']) UserSession.instance.setUser(result['data']);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: _headers,
        body: jsonEncode(data),
      );
      final result = await _handleResponse(res);
      if (result['success']) UserSession.instance.setUser(result['data']);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users/change-password'),
        headers: _headers,
        body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/users/delete'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ════════════════════════════════════════
  //  STATIONS
  // ════════════════════════════════════════

  // Get all stations
  Future<Map<String, dynamic>> getStations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stations'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Get one station
  Future<Map<String, dynamic>> getStation(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stations/$id'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ════════════════════════════════════════
  //  BOOKINGS
  // ════════════════════════════════════════

  // Get my bookings
  Future<Map<String, dynamic>> getBookings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/bookings'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Create booking
  Future<Map<String, dynamic>> createBooking({
    required String stationId,
    required String date,
    required String time,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: _headers,
        body: jsonEncode({'stationId': stationId, 'date': date, 'time': time}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Cancel booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final res = await http.put(
          Uri.parse('$baseUrl/bookings/$bookingId/cancel'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ════════════════════════════════════════
  //  PAYMENTS
  // ════════════════════════════════════════

  // Get transactions
  Future<Map<String, dynamic>> getTransactions() async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/payments/transactions'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Top up
  Future<Map<String, dynamic>> topUp(double amount) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payments/topup'),
        headers: _headers,
        body: jsonEncode({'amount': amount}),
      );
      final result = await _handleResponse(res);
      if (result['success']) {
        UserSession.instance.updateBalance(result['data']['balance']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // Transfer
  Future<Map<String, dynamic>> transfer({
    required double amount,
    required String destination,
    required String typeName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/payments/transfer'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'destination': destination,
          'typeName': typeName,
        }),
      );
      final result = await _handleResponse(res);
      if (result['success']) {
        UserSession.instance.updateBalance(result['data']['balance']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }
}

// ════════════════════════════════════════
//  USER SESSION — global user state
// ════════════════════════════════════════
class UserSession extends ChangeNotifier {
  static final UserSession instance = UserSession._();
  UserSession._();

  Map<String, dynamic>? _user;

  // Getters
  bool   get isLoggedIn  => _user != null;
  String get firstName   => _user?['firstName']  ?? '';
  String get lastName    => _user?['lastName']   ?? '';
  String get fullName    => '$firstName $lastName'.trim();
  String get email       => _user?['email']      ?? '';
  String get phone       => _user?['phone']      ?? '';
  String get role        => _user?['role']       ?? 'driver';
  String get vehicle     => _user?['vehicle']    ?? '';
  String get connector   => _user?['connector']  ?? 'CCS2';
  String get avatar      => _user?['avatar']     ?? '';
  String get region      => _user?['region']     ?? 'Palestine';
  double get balance     => (_user?['balance']   ?? 0).toDouble();
  int    get points      => _user?['points']     ?? 0;
  String get id          => _user?['_id']        ?? '';

  void setUser(Map<String, dynamic> data) {
    _user = data;
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user!['balance'] = newBalance;
      notifyListeners();
    }
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

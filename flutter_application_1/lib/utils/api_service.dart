import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════
//  API SERVICE — ChargeGuard Backend
// ════════════════════════════════════════
class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Singleton
  static final ApiService instance = ApiService._();
  ApiService._();

  // JWT token (set after login)
  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  // ── Save token to localStorage ───────────────────────────
  void setToken(String token) {
    _token = token;
    html.window.localStorage['cg_token'] = token;
  }

  void clearToken() {
    _token = null;
    html.window.localStorage.remove('cg_token');
    html.window.localStorage.remove('cg_user');
  }

  // ── Load token from localStorage on app start ────────────
  Future<bool> tryAutoLogin() async {
    final token    = html.window.localStorage['cg_token'];
    final userJson = html.window.localStorage['cg_user'];
    if (token == null || userJson == null) return false;

    try {
      _token = token;
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      UserSession.instance.setUser(userData);
      // Load fresh profile to get latest batteryPct and balance
      getProfile().then((result) {
        if (result['success']) {
          final data = result['data'] as Map<String, dynamic>;
          UserSession.instance.setUser(data);
          // Update localStorage with fresh data
          html.window.localStorage['cg_user'] = jsonEncode(data);
        }
      });
      return true;
    } catch (e) {
      clearToken();
      return false;
    }
  }

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
        setToken(result['data']['token']);
        UserSession.instance.setUser(result['data']);
        html.window.localStorage['cg_user'] = jsonEncode(result['data']);
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
    bool rememberMe = true,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final result = await _handleResponse(res);
      if (result['success']) {
        setToken(result['data']['token']);
        UserSession.instance.setUser(result['data']);
        if (rememberMe) {
          // Save to localStorage — persists after browser close
          html.window.localStorage['cg_token'] = result['data']['token'];
          html.window.localStorage['cg_user']  = jsonEncode(result['data']);
        } else {
          // Clear localStorage — session only
          html.window.localStorage.remove('cg_token');
          html.window.localStorage.remove('cg_user');
        }
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
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

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

  // ── Support ───────────────────────────────────────────────
  Future<Map<String, dynamic>> submitTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/support/ticket'),
        headers: _headers,
        body: jsonEncode({'category': category, 'subject': subject, 'message': message}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getChatMessages() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/support/chat'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(String text) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/support/chat'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Host ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHostStats() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/stats'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostStations() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/stations'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> addHostStation(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/host/stations'),
          headers: _headers, body: jsonEncode(data));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> toggleStation(String stationId) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/host/stations/$stationId/toggle'),
          headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostBookings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/bookings'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostAnalytics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/analytics'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateHostStation(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/host/stations/$id'),
          headers: _headers, body: jsonEncode(data));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostProfile() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/profile'), headers: _headers);
      final result = await _handleResponse(res);
      if (result['success']) {
        // Update UserSession with fresh data
        final data = result['data'] as Map<String, dynamic>;
        UserSession.instance.setUser({...?UserSession.instance.user, ...data});
        // Update localStorage
        final stored = html.window.localStorage['cg_user'];
        if (stored != null) {
          final old = jsonDecode(stored) as Map<String, dynamic>;
          html.window.localStorage['cg_user'] = jsonEncode({...old, ...data});
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateHostProfile(Map<String, dynamic> data) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/host/profile'),
          headers: _headers, body: jsonEncode(data));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostPayouts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/payouts'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> requestPayout(double amount) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/host/payouts/request'),
          headers: _headers, body: jsonEncode({'amount': amount}));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostReviews() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/reviews'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> registerHost({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String idImage,
    required String licenseImage,
    String businessName = '',
    String phone = '',
    String bankName = '',
    String iban = '',
  }) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/register-host'),
          headers: _headers,
          body: jsonEncode({
            'firstName': firstName, 'lastName': lastName,
            'email': email, 'password': password,
            'businessName': businessName, 'phone': phone,
            'bankName': bankName, 'iban': iban,
            'idImage': idImage, 'licenseImage': licenseImage,
          }));
      final result = await _handleResponse(res);
      if (result['success']) {
        final data = result['data'] as Map<String, dynamic>;
        setToken(data['token'] as String);
        UserSession.instance.setUser(data);
        html.window.localStorage['cg_user'] = jsonEncode(data);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostStatus() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/host/status'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Admin ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPendingHosts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/hosts/pending'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAllHosts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/hosts/all'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getHostDetails(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/hosts/$id'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> approveHost(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/hosts/$id/approve'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> rejectHost(String id, String reason) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/hosts/$id/reject'),
          headers: _headers, body: jsonEncode({'reason': reason}));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getBookmarks() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/bookmarks'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getBookmarkIds() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/bookmarks/ids'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> addBookmark(String stationId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/bookmarks/$stationId'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> removeBookmark(String stationId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/bookmarks/$stationId'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/analytics'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/users'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> updateUserBalance(String id, double balance) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/users/$id/balance'),
          headers: _headers, body: jsonEncode({'balance': balance}));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/admin/users/$id'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAllStationsAdmin() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/stations'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> toggleStationAdmin(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/stations/$id/toggle'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteStation(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/admin/stations/$id'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAllPayouts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/payouts'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> approvePayout(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/payouts/$id/approve'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> rejectPayout(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/payouts/$id/reject'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getAllTickets() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/tickets'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resolveTicket(String id) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/admin/tickets/$id/resolve'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Offers ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOffers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/offers'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> claimOffer(String offerId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/offers/claim/$offerId'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> getMyClaims() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/offers/my-claims'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Stats ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/users/stats'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Battery ───────────────────────────────────────────────
  Future<void> saveBattery(int pct) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/users/battery'),
        headers: _headers,
        body: jsonEncode({'batteryPct': pct}),
      );
    } catch (_) {}
  }

  // ── Avatar Upload ─────────────────────────────────────────
  Future<Map<String, dynamic>> uploadAvatar(String base64) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users/avatar'),
        headers: _headers,
        body: jsonEncode({'avatar': base64}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Cards ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCards() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/cards'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> addCard(Map<String, dynamic> card) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/cards'),
          headers: _headers, body: jsonEncode(card));
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> setDefaultCard(String cardId) async {
    try {
      final res = await http.put(
          Uri.parse('$baseUrl/cards/$cardId/default'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> deleteCard(String cardId) async {
    try {
      final res = await http.delete(
          Uri.parse('$baseUrl/cards/$cardId'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── AI Recommendation ────────────────────────────────────
  Future<Map<String, dynamic>> getRecommendation() async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/ai/recommend'), headers: _headers);
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  // ── Charging Session ─────────────────────────────────────
  Future<Map<String, dynamic>> startCharging(String stationId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/charging/start'),
        headers: _headers,
        body: jsonEncode({'stationId': stationId}),
      );
      return await _handleResponse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> stopCharging({
    required String stationId,
    required double kwhCharged,
    required int duration,
    int? batteryPct,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/charging/stop'),
        headers: _headers,
        body: jsonEncode({
          'stationId':  stationId,
          'kwhCharged': kwhCharged,
          'duration':   duration,
          'batteryPct': batteryPct ?? UserSession.instance.batteryPct,
        }),
      );
      return await _handleResponse(res);
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
  Map<String, dynamic>? get user => _user;

  // Bookmark notifier — يتحدث لما يتضاف/يحذف bookmark
  final bookmarkNotifier = ValueNotifier<int>(0);
  void notifyBookmarkChange() => bookmarkNotifier.value++;

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
  String get hostStatus  => _user?['hostStatus'] ?? 'Approved';

  void setUser(Map<String, dynamic> data) {
    _user = data;
    // Load battery from backend
    if (data['batteryPct'] != null) {
      _batteryPct = (data['batteryPct'] as num).toInt();
    }
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user!['balance'] = newBalance;
      notifyListeners();
    }
  }

  void setAvatar(String base64) {
    if (_user != null) {
      _user!['avatar'] = base64;
      notifyListeners();
    }
  }

  // Battery tracking
  int _batteryPct = 65;
  int get batteryPct => _batteryPct;

  void updateBattery(int pct) {
    _batteryPct = pct;
    notifyListeners();
    // Save to backend
    ApiService.instance.saveBattery(pct);
  }

  // ── Active Charging Session ───────────────────────────────
  bool   _isCharging   = false;
  int    _chargeSecs   = 0;
  double _chargeKwh    = 0;
  double _chargeCost   = 0;
  String _chargeName   = '';
  String _chargeStationId = '';

  bool   get isCharging      => _isCharging;
  int    get chargeSecs      => _chargeSecs;
  double get chargeKwh       => _chargeKwh;
  double get chargeCost      => _chargeCost;
  String get chargeName      => _chargeName;
  String get chargeStationId => _chargeStationId;

  void startChargingSession(String stationId, String stationName) {
    _isCharging      = true;
    _chargeSecs      = 0;
    _chargeKwh       = 0;
    _chargeCost      = 0;
    _chargeName      = stationName;
    _chargeStationId = stationId;
    notifyListeners();
  }

  void updateChargingSession(int secs, double kwh, double cost) {
    _chargeSecs = secs;
    _chargeKwh  = kwh;
    _chargeCost = cost;
    notifyListeners();
  }

  void stopChargingSession(int finalBattery) {
    _isCharging  = false;
    _batteryPct  = finalBattery;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

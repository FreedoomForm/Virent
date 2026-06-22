import '../models/models.dart';
import '../../../../core/configs/services/api_client.dart';

/// Repository that talks to the Virent backend.
/// On desktop, this is the embedded server (localhost:8443).
/// On mobile, this is the desktop PC's IP (user-configurable).
class VirentRepository {
  final ApiClient _api;

  VirentRepository([ApiClient? api]) : _api = api ?? ApiClient();

  // ---- Auth ----
  Future<Map<String, dynamic>> sendOtp(String phone) =>
      _api.post('/auth/phone/send-code', {'phone': phone});

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) =>
      _api.post('/auth/phone/verify', {'phone': phone, 'code': code});

  // ---- Scooters ----
  Future<List<Scooter>> getNearbyScooters(double lat, double lng) async {
    final data = await _api.get('/scooters/nearby?lat=$lat&lng=$lng');
    final list = data['scooters'] as List? ?? [];
    return list.map((s) => Scooter.fromJson(s)).toList();
  }

  // ---- Trips ----
  Future<Map<String, dynamic>> startTrip(String scooterId) =>
      _api.post('/trips/start', {'scooter_id': scooterId});

  Future<Map<String, dynamic>> endTrip(String tripId) =>
      _api.post('/trips/end', {'trip_id': tripId});

  Future<List<Trip>> getTrips() async {
    final data = await _api.get('/trips');
    final list = data['trips'] as List? ?? [];
    return list.map((t) => Trip.fromJson(t)).toList();
  }

  // ---- User ----
  Future<User> getProfile() async {
    final data = await _api.get('/users/me');
    return User.fromJson(data['user']);
  }

  // ---- Wallet ----
  Future<Map<String, dynamic>> getWallet() => _api.get('/wallet');

  Future<Map<String, dynamic>> topUp(int amount) =>
      _api.post('/wallet/topup', {'amount': amount});

  // ---- Admin (desktop only) ----
  Future<Map<String, dynamic>> getStats() => _api.get('/admin/stats');

  Future<List<Scooter>> getAllScooters() async {
    final data = await _api.get('/admin/scooters');
    final list = data['scooters'] as List? ?? [];
    return list.map((s) => Scooter.fromJson(s)).toList();
  }
}

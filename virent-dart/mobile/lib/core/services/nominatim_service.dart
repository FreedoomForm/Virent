// nominatim_service.dart — Open-Source geocoding client.
//
// Free, key-less alternative to Google Places / Mapbox Geocoding. The
// Nominatim project (https://nominatim.org/) is the geocoder that powers
// the OpenStreetMap website. A public instance runs at
// `nominatim.openstreetmap.org` and is free to use subject to a fair-use
// policy (https://operations.osmfoundation.org/policies/nominatim/):
//
//   * Send a valid `User-Agent` (or `Referer`) header identifying the app.
//   * No more than 1 request per second per IP.
//   * No more than 2 concurrent requests per IP.
//
// For production traffic a fleet operator should host their own Nominatim
// instance (the project ships a Docker image) and point
// [NominatimService.baseUrl] at it — the policy above only applies to the
// shared public server.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../error/api_exceptions.dart';

/// One geocoding result returned by Nominatim.
///
/// [displayName] is the full, comma-separated address line. [address]
/// mirrors Nominatim's `addressdetails=1` payload (a map keyed by OSM
/// address parts: `road`, `city`, `country`, etc.) so callers can build
/// compact UI strings without re-parsing.
class NominatimResult {
  /// Creates a [NominatimResult].
  const NominatimResult({
    required this.lat,
    required this.lng,
    required this.displayName,
    this.address = const <String, dynamic>{},
    this.placeId,
  });

  /// Latitude of the matched feature (WGS84).
  final double lat;

  /// Longitude of the matched feature (WGS84).
  final double lng;

  /// Full, human-readable address line.
  final String displayName;

  /// Structured address parts (Nominatim `address` object).
  final Map<String, dynamic> address;

  /// Nominatim `place_id` — useful as a stable cache key.
  final String? placeId;

  /// Convenience accessor for `flutter_map` / `latlong2`.
  LatLng get location => LatLng(lat, lng);

  @override
  String toString() => 'NominatimResult($lat, $lng, "$displayName")';
}

/// Riverpod provider exposing a singleton [NominatimService] pointed at the
/// public Nominatim instance.
///
/// Override in `main.dart` to point at a self-hosted instance:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     nominatimServiceProvider.overrideWithValue(
///       NominatimService(baseUrl: 'https://geocode.my-fleet.com'),
///     ),
///   ],
///   child: const VirentApp(),
/// )
/// ```
final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});

/// Thin HTTP client for a Nominatim server.
///
/// Both [search] (forward geocoding) and [reverseGeocode] (reverse
/// geocoding) are supported. Failures are funnelled through
/// [ApiException] so callers can `try / catch` a single error hierarchy.
class NominatimService {
  /// Creates a [NominatimService].
  ///
  /// Pass [baseUrl] to use a self-hosted Nominatim instance. [userAgent]
  /// is sent as the `User-Agent` header — Nominatim's policy requires it
  /// to identify the calling application.
  NominatimService({
    String? baseUrl,
    this.userAgent = 'com.virent.mobile/1.0 (flutter)',
  }) : baseUrl = (baseUrl ?? 'https://nominatim.openstreetmap.org').trim();

  /// Base URL of the Nominatim server, without a trailing slash.
  final String baseUrl;

  /// `User-Agent` header sent on every request (per Nominatim policy).
  final String userAgent;

  /// Per-request timeout.
  static const Duration _timeout = Duration(seconds: 10);

  /// Forward-geocodes [query] into one or more [NominatimResult]s.
  ///
  /// Returns at most [limit] results (default 5). Pass [countryCode] as
  /// an ISO-3166 alpha-2 code (e.g. `uz`) to bias results towards a
  /// country — useful on the home screen where the rider is almost
  /// always searching for nearby places.
  ///
  /// Returns an empty list when [query] is blank.
  Future<List<NominatimResult>> search(
    String query, {
    int limit = 5,
    String? countryCode,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <NominatimResult>[];

    final params = <String, String>{
      'q': trimmed,
      'format': 'json',
      'limit': limit.toString(),
      'addressdetails': '1',
    };
    if (countryCode != null && countryCode.isNotEmpty) {
      params['countrycodes'] = countryCode;
    }
    final uri =
        Uri.parse('$baseUrl/search').replace(queryParameters: params);

    final res = await http.get(uri, headers: {
      'User-Agent': userAgent,
      'Accept': 'application/json',
    }).timeout(_timeout);

    if (res.statusCode != 200) {
      throw ApiException(
        'Nominatim search failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final list = jsonDecode(res.body);
    if (list is! List) return const <NominatimResult>[];
    return list
        .map((e) => _parse(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Reverse-geocodes [lat], [lng] into a single address string.
  ///
  /// Returns an empty string when Nominatim could not find a feature at
  /// the supplied coordinates (e.g. the middle of an ocean).
  Future<String> reverseGeocode(
    double lat,
    double lng, {
    String language = 'en',
  }) async {
    final uri = Uri.parse('$baseUrl/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
      'addressdetails': '1',
      'accept-language': language,
    });

    final res = await http.get(uri, headers: {
      'User-Agent': userAgent,
      'Accept': 'application/json',
    }).timeout(_timeout);

    if (res.statusCode != 200) {
      throw ApiException(
        'Nominatim reverse failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return '';
    return (body['display_name'] ?? '').toString();
  }

  /// Maps one Nominatim JSON object to a [NominatimResult].
  ///
  /// Nominatim serialises lat/lon as strings (e.g. `"41.3111"`) so we
  /// parse defensively.
  NominatimResult _parse(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}') ?? 0;
    final lng = double.tryParse('${json['lon']}') ?? 0;
    final address = json['address'];
    return NominatimResult(
      lat: lat,
      lng: lng,
      displayName: (json['display_name'] ?? '').toString(),
      address: address is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(address)
          : const <String, dynamic>{},
      placeId: json['place_id']?.toString(),
    );
  }
}

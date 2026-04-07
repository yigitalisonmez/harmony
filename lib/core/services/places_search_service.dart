import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PlaceResult {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? category;
  final double? rating;

  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.category,
    this.rating,
  });

  String get categoryLabel {
    if (category == null) return '';
    const map = {
      'cafe': '☕ Cafe',
      'restaurant': '🍽 Restaurant',
      'bar': '🍸 Bar',
      'bakery': '🥐 Bakery',
      'food': '🍴 Food',
      'lodging': '🏨 Hotel',
      'tourist_attraction': '📍 Attraction',
      'park': '🌿 Park',
      'museum': '🏛 Museum',
      'movie_theater': '🎬 Cinema',
    };
    return map[category] ?? category!;
  }
}

class PlacesSearchService {
  static const _base = 'https://places.googleapis.com/v1/places:searchText';

  static const _fieldMask =
      'places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating';

  /// Search using Places API (New) — Text Search endpoint.
  static Future<List<PlaceResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_base);

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': ApiConfig.googlePlacesKey,
            'X-Goog-FieldMask': _fieldMask,
          },
          body: jsonEncode({
            'textQuery': query.trim(),
            'languageCode': 'tr',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 403) {
      throw Exception('API key invalid or Places API (New) not enabled.');
    }
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final places = (body['places'] as List?) ?? [];

    const priority = [
      'cafe', 'restaurant', 'bar', 'bakery', 'food',
      'lodging', 'tourist_attraction', 'park', 'museum', 'movie_theater',
    ];

    return places.map((r) {
      final loc = r['location'] as Map<String, dynamic>;
      final types = (r['types'] as List?)?.cast<String>() ?? [];
      final cat = types.firstWhere(
        (t) => priority.contains(t),
        orElse: () => types.isNotEmpty ? types.first : '',
      );
      final displayName = r['displayName'] as Map<String, dynamic>?;

      return PlaceResult(
        placeId: r['id'] as String? ?? '',
        name: displayName?['text'] as String? ?? '',
        address: r['formattedAddress'] as String? ?? '',
        lat: (loc['latitude'] as num).toDouble(),
        lng: (loc['longitude'] as num).toDouble(),
        category: cat.isNotEmpty ? cat : null,
        rating: (r['rating'] as num?)?.toDouble(),
      );
    }).toList();
  }
}

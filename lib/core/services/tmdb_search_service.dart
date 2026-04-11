import 'dart:convert';
import 'package:http/http.dart' as http;

// Get a free API key from https://www.themoviedb.org/settings/api
const _kTmdbApiKey = 'b2663d2ecb14705de4c6f676b8017b29';

class TmdbMovieResult {
  final int tmdbId;
  final String title;
  final String year;
  final String? posterPath;
  final double? rating;

  const TmdbMovieResult({
    required this.tmdbId,
    required this.title,
    required this.year,
    this.posterPath,
    this.rating,
  });

  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w200$posterPath' : null;

  static TmdbMovieResult fromJson(Map<String, dynamic> m) => TmdbMovieResult(
        tmdbId: m['id'] as int,
        title: m['title'] as String? ?? '',
        year: ((m['release_date'] as String?) ?? '').split('-').first,
        posterPath: m['poster_path'] as String?,
        rating: (m['vote_average'] as num?) != null
            ? (m['vote_average'] as num).toDouble()
            : null,
      );
}

class TmdbSearchService {
  static Future<List<TmdbMovieResult>> search(String query) async {
    final uri = Uri.https('api.themoviedb.org', '/3/search/movie', {
      'api_key': _kTmdbApiKey,
      'query': query,
      'language': 'en-US',
      'page': '1',
      'include_adult': 'false',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('TMDB error ${res.statusCode}');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .take(10)
        .map(TmdbMovieResult.fromJson)
        .toList();

    return results;
  }
}

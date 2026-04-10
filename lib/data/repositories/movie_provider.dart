import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'movie_repository.dart';

export 'movie_repository.dart' show MovieItem;

final _repoProvider = Provider<MovieRepository>((_) => MovieRepository());

final moviesProvider =
    StateNotifierProvider<MoviesNotifier, List<MovieItem>>(
        (ref) => MoviesNotifier(ref.watch(_repoProvider)));

class MoviesNotifier extends StateNotifier<List<MovieItem>> {
  MoviesNotifier(this._repo) : super([]) {
    _load();
  }

  final MovieRepository _repo;

  void _load() => state = _repo.getAll();

  Future<void> add(String title) async {
    await _repo.add(MovieItem(
      id: MovieRepository.newId(),
      title: title,
      isWatched: false,
      createdAt: DateTime.now(),
    ));
    _load();
  }

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    _load();
  }

  Future<void> updateTitle(String id, String title) async {
    await _repo.updateTitle(id, title);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}

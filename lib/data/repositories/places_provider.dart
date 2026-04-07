import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'places_repository.dart';

export 'places_repository.dart' show PlaceItem;

final _repoProvider =
    Provider<PlacesRepository>((_) => PlacesRepository());

final placesProvider =
    StateNotifierProvider<PlacesNotifier, List<PlaceItem>>(
        (ref) => PlacesNotifier(ref.watch(_repoProvider)));

class PlacesNotifier extends StateNotifier<List<PlaceItem>> {
  PlacesNotifier(this._repo) : super([]) {
    _load();
  }

  final PlacesRepository _repo;

  void _load() => state = _repo.getAll();

  Future<void> add(PlaceItem item) async {
    await _repo.add(item);
    _load();
  }

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}

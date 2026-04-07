import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bucket_list_repository.dart';

export 'bucket_list_repository.dart' show BucketItem;

final _repoProvider = Provider<BucketListRepository>((_) => BucketListRepository());

final bucketListProvider =
    StateNotifierProvider<BucketListNotifier, List<BucketItem>>(
        (ref) => BucketListNotifier(ref.watch(_repoProvider)));

class BucketListNotifier extends StateNotifier<List<BucketItem>> {
  BucketListNotifier(this._repo) : super([]) {
    _load();
  }

  final BucketListRepository _repo;

  void _load() => state = _repo.getAll();

  Future<void> add(String title) async {
    await _repo.add(title.trim());
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

  Future<void> updateTitle(String id, String title) async {
    await _repo.updateTitle(id, title.trim());
    _load();
  }
}

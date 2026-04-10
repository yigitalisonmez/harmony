import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class MovieItem {
  final String id;
  final String title;
  final bool isWatched;
  final DateTime createdAt;

  const MovieItem({
    required this.id,
    required this.title,
    required this.isWatched,
    required this.createdAt,
  });

  MovieItem copyWith({String? title, bool? isWatched}) => MovieItem(
        id: id,
        title: title ?? this.title,
        isWatched: isWatched ?? this.isWatched,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isWatched': isWatched,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static MovieItem fromMap(Map map) => MovieItem(
        id: map['id'] as String,
        title: map['title'] as String,
        isWatched: map['isWatched'] as bool,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}

class MovieRepository {
  static const _boxName = 'movies';
  static const _uuid = Uuid();

  static Future<void> init() async => Hive.openBox(_boxName);
  static Box get _box => Hive.box(_boxName);

  List<MovieItem> getAll() => _box.values
      .map((e) => MovieItem.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> add(MovieItem item) async => _box.put(item.id, item.toMap());

  Future<void> toggle(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final item = MovieItem.fromMap(Map<String, dynamic>.from(raw as Map));
    await _box.put(id, item.copyWith(isWatched: !item.isWatched).toMap());
  }

  Future<void> updateTitle(String id, String title) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final item = MovieItem.fromMap(Map<String, dynamic>.from(raw as Map));
    await _box.put(id, item.copyWith(title: title).toMap());
  }

  Future<void> delete(String id) async => _box.delete(id);

  static String newId() => _uuid.v4();
}

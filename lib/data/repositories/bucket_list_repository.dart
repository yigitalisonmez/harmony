import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class BucketItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  const BucketItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  BucketItem copyWith({String? title, bool? isCompleted}) => BucketItem(
        id: id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static BucketItem fromMap(Map map) => BucketItem(
        id: map['id'] as String,
        title: map['title'] as String,
        isCompleted: map['isCompleted'] as bool,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );
}

class BucketListRepository {
  static const _boxName = 'bucket_list';
  static const _uuid = Uuid();

  static Future<void> init() async => Hive.openBox(_boxName);
  static Box get _box => Hive.box(_boxName);

  List<BucketItem> getAll() {
    return _box.values
        .map((e) => BucketItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> add(String title) async {
    final item = BucketItem(
      id: _uuid.v4(),
      title: title,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await _box.put(item.id, item.toMap());
  }

  Future<void> toggle(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final item = BucketItem.fromMap(Map<String, dynamic>.from(raw as Map));
    await _box.put(id, item.copyWith(isCompleted: !item.isCompleted).toMap());
  }

  Future<void> delete(String id) async => _box.delete(id);

  Future<void> updateTitle(String id, String title) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final item = BucketItem.fromMap(Map<String, dynamic>.from(raw as Map));
    await _box.put(id, item.copyWith(title: title).toMap());
  }
}

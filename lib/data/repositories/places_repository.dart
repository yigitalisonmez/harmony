import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class PlaceItem {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? category;
  final double? rating;
  final bool isVisited;
  final DateTime createdAt;

  const PlaceItem({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.category,
    this.rating,
    required this.isVisited,
    required this.createdAt,
  });

  PlaceItem copyWith({bool? isVisited}) => PlaceItem(
        id: id,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        category: category,
        rating: rating,
        isVisited: isVisited ?? this.isVisited,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'category': category,
        'rating': rating,
        'isVisited': isVisited,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static PlaceItem fromMap(Map map) => PlaceItem(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        category: map['category'] as String?,
        rating: (map['rating'] as num?)?.toDouble(),
        isVisited: map['isVisited'] as bool,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

class PlacesRepository {
  static const _boxName = 'places';
  static const _uuid = Uuid();

  static Future<void> init() async => Hive.openBox(_boxName);
  static Box get _box => Hive.box(_boxName);

  List<PlaceItem> getAll() => _box.values
      .map((e) => PlaceItem.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> add(PlaceItem item) async =>
      _box.put(item.id, item.toMap());

  Future<void> toggle(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final item = PlaceItem.fromMap(Map<String, dynamic>.from(raw as Map));
    await _box.put(id, item.copyWith(isVisited: !item.isVisited).toMap());
  }

  Future<void> delete(String id) async => _box.delete(id);

  static String newId() => _uuid.v4();
}

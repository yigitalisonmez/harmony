import 'package:hive_flutter/hive_flutter.dart';

part 'memory.g.dart';

@HiveType(typeId: 0)
class Memory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String photoPath;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? location;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isFavourite;

  /// 64 ARGB color values representing the 8×8 pixel map of the photo.
  @HiveField(7)
  final List<int>? pixelMap;

  Memory({
    required this.id,
    required this.photoPath,
    required this.date,
    this.location,
    this.note,
    required this.createdAt,
    this.isFavourite = false,
    this.pixelMap,
  });

  Memory copyWith({
    String? id,
    String? photoPath,
    DateTime? date,
    String? location,
    String? note,
    DateTime? createdAt,
    bool? isFavourite,
    List<int>? pixelMap,
  }) {
    return Memory(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
      date: date ?? this.date,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isFavourite: isFavourite ?? this.isFavourite,
      pixelMap: pixelMap ?? this.pixelMap,
    );
  }
}

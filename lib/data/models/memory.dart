import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'memory.g.dart';

// Sentinel for distinguishing "not passed" from null in copyWith.
const Object _sentinel = Object();

@HiveType(typeId: 0)
class Memory extends HiveObject {
  @HiveField(0)
  final String id;

  /// Local file path (used while uploading / offline fallback).
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

  /// Firebase Storage download URL (null until upload completes).
  @HiveField(8)
  final String? photoUrl;

  /// Short emoji / message left by the partner on this memory.
  final String? partnerReaction;

  Memory({
    required this.id,
    required this.photoPath,
    required this.date,
    this.location,
    this.note,
    required this.createdAt,
    this.isFavourite = false,
    this.pixelMap,
    this.photoUrl,
    this.partnerReaction,
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
    String? photoUrl,
    Object? partnerReaction = _sentinel,
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
      photoUrl: photoUrl ?? this.photoUrl,
      partnerReaction: partnerReaction == _sentinel
          ? this.partnerReaction
          : partnerReaction as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'photoUrl': photoUrl,
        'date': Timestamp.fromDate(date),
        'location': location,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'isFavourite': isFavourite,
        'pixelMap': pixelMap,
        'partnerReaction': partnerReaction,
      };

  static Memory fromFirestore(Map<String, dynamic> data) => Memory(
        id: data['id'] as String,
        photoPath: '', // Remote memories have no local path
        date: (data['date'] as Timestamp).toDate(),
        location: data['location'] as String?,
        note: data['note'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        isFavourite: data['isFavourite'] as bool? ?? false,
        pixelMap: data['pixelMap'] != null
            ? List<int>.from(data['pixelMap'] as List)
            : null,
        photoUrl: data['photoUrl'] as String?,
        partnerReaction: data['partnerReaction'] as String?,
      );
}

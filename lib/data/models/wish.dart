class Wish {
  final String id;
  final String text;
  final String creatorUid;
  final String creatorName;
  final String? joinedUid;
  final String? joinedName;
  final DateTime createdAt;

  const Wish({
    required this.id,
    required this.text,
    required this.creatorUid,
    required this.creatorName,
    this.joinedUid,
    this.joinedName,
    required this.createdAt,
  });

  bool get isJoined => joinedUid != null;

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'text': text,
        'creatorUid': creatorUid,
        'creatorName': creatorName,
        'joinedUid': joinedUid,
        'joinedName': joinedName,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  static Wish fromFirestore(Map<String, dynamic> d) => Wish(
        id: d['id'] as String,
        text: d['text'] as String,
        creatorUid: d['creatorUid'] as String,
        creatorName: d['creatorName'] as String,
        joinedUid: d['joinedUid'] as String?,
        joinedName: d['joinedName'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(d['createdAt'] as int),
      );

  Wish copyWith({String? joinedUid, String? joinedName}) => Wish(
        id: id,
        text: text,
        creatorUid: creatorUid,
        creatorName: creatorName,
        joinedUid: joinedUid ?? this.joinedUid,
        joinedName: joinedName ?? this.joinedName,
        createdAt: createdAt,
      );
}

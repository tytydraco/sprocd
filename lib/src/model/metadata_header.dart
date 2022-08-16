/// Holds an initial time in milliseconds and an ID in the form of a [String].
class MetadataHeader {
  /// Creates a new [MetadataHeader] given an [initTime] and an [id].
  MetadataHeader({
    required this.initTime,
    required this.id,
  });

  /// Creates a new [MetadataHeader] from a formatted [String].
  factory MetadataHeader.fromString(String string) {
    if (!string.contains(':')) {
      throw ArgumentError('Malformed formatting', 'string');
    }

    final parts = string.split(':');
    final initTimeMsStr = parts[0];
    final idStr = parts[1];

    final initTimeMs = int.tryParse(initTimeMsStr);
    if (initTimeMs == null) {
      throw ArgumentError('Malformed initial time part', 'string');
    }

    final id = int.tryParse(idStr);
    if (id == null) {
      throw ArgumentError('Malformed ID part', 'string');
    }

    final initTime = DateTime.fromMillisecondsSinceEpoch(initTimeMs);

    return MetadataHeader(initTime: initTime, id: id);
  }

  /// The starting time.
  final DateTime initTime;

  /// The entry ID.
  final int id;

  /// Returns the formatted [String], formatted as the [initTime] in
  /// milliseconds and the [id], separated by a colon.
  @override
  String toString() {
    return '${initTime.millisecondsSinceEpoch}:$id';
  }
}

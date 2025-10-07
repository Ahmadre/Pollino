import 'package:hive_flutter/hive_flutter.dart';

/// Service für lokale Speicherung von Likes mit Hive
/// Speichert welche Umfragen der User bereits geliked hat
class LikeService {
  static const String _boxName = 'liked_polls';
  static Box<bool>? _likedPollsBox;

  /// Initialisiert den LikeService
  static Future<void> init() async {
    if (_likedPollsBox == null || !_likedPollsBox!.isOpen) {
      _likedPollsBox = await Hive.openBox<bool>(_boxName);
    }
  }

  /// Stellt sicher, dass die Box geöffnet ist
  static Future<Box<bool>> _getBox() async {
    if (_likedPollsBox == null || !_likedPollsBox!.isOpen) {
      await init();
    }
    return _likedPollsBox!;
  }

  /// Gibt zurück, ob eine Umfrage bereits geliked wurde
  static Future<bool> hasUserMadeLike(String pollId) async {
    final box = await _getBox();
    return box.get(pollId, defaultValue: false) ?? false;
  }

  /// Togglet den Like-Status einer Umfrage
  /// Gibt zurück, ob die Umfrage nach dem Toggle geliked ist
  static Future<bool> toggleLike(String pollId) async {
    final box = await _getBox();
    final currentStatus = box.get(pollId, defaultValue: false) ?? false;
    final newStatus = !currentStatus;

    if (newStatus) {
      // Like: Speichere true
      await box.put(pollId, true);
    } else {
      // Unlike: Entferne den Eintrag
      await box.delete(pollId);
    }

    return newStatus;
  }

  /// Gibt alle gelikten Poll-IDs zurück
  static Future<List<String>> getLikedPolls() async {
    final box = await _getBox();
    return box.keys.cast<String>().where((key) => box.get(key) == true).toList();
  }

  /// Löscht alle Like-Daten (für Debug/Reset-Zwecke)
  static Future<void> clearAllLikes() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Schließt die Hive Box (sollte beim Beenden der App aufgerufen werden)
  static Future<void> dispose() async {
    if (_likedPollsBox != null && _likedPollsBox!.isOpen) {
      await _likedPollsBox!.close();
    }
  }
}

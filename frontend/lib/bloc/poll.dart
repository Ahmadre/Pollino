import 'package:hive/hive.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll.freezed.dart';
part 'poll.g.dart';

@HiveType(typeId: 0)
@freezed
class Poll with _$Poll {
  @HiveType(typeId: 0)
  const factory Poll({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) String? description,
    @HiveField(3) required List<Option> options,
    @HiveField(4) @Default(true) bool isAnonymous,
    @HiveField(5) String? createdByName,
    @HiveField(6) String? createdBy,
    @HiveField(7) @Default(false) bool allowsMultipleVotes,
    @HiveField(8) DateTime? expiresAt,
    @HiveField(9) @Default(false) bool autoDeleteAfterExpiry,
    @HiveField(10) @Default(0) int likesCount,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}

@HiveType(typeId: 1)
@freezed
class Option with _$Option {
  @HiveType(typeId: 1)
  const factory Option({
    @HiveField(0) required String id,
    @HiveField(1) required String text,
    @HiveField(2) required int votes,
    @HiveField(3) @Default(0) int order,
  }) = _Option;

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);
}

// Custom Hive Adapter für bessere Null-Safety
class SafeOptionAdapter extends TypeAdapter<Option> {
  @override
  final int typeId = 1;

  @override
  Option read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Option(
      id: fields[0] as String,
      text: fields[1] as String,
      votes: fields[2] as int,
      order: (fields[3] as int?) ?? 0, // Null-safe mit Fallback auf 0
    );
  }

  @override
  void write(BinaryWriter writer, Option obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.votes)
      ..writeByte(3)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeOptionAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

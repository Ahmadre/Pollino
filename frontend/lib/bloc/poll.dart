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
  }) = _Option;

  factory Option.fromJson(Map<String, dynamic> json) => _$OptionFromJson(json);
}

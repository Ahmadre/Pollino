// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pull_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PollEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollEventCopyWith<$Res> {
  factory $PollEventCopyWith(PollEvent value, $Res Function(PollEvent) then) =
      _$PollEventCopyWithImpl<$Res, PollEvent>;
}

/// @nodoc
class _$PollEventCopyWithImpl<$Res, $Val extends PollEvent>
    implements $PollEventCopyWith<$Res> {
  _$PollEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadPollsImplCopyWith<$Res> {
  factory _$$LoadPollsImplCopyWith(
          _$LoadPollsImpl value, $Res Function(_$LoadPollsImpl) then) =
      __$$LoadPollsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int page, int limit});
}

/// @nodoc
class __$$LoadPollsImplCopyWithImpl<$Res>
    extends _$PollEventCopyWithImpl<$Res, _$LoadPollsImpl>
    implements _$$LoadPollsImplCopyWith<$Res> {
  __$$LoadPollsImplCopyWithImpl(
      _$LoadPollsImpl _value, $Res Function(_$LoadPollsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_$LoadPollsImpl(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LoadPollsImpl with DiagnosticableTreeMixin implements LoadPolls {
  const _$LoadPollsImpl({required this.page, required this.limit});

  @override
  final int page;
  @override
  final int limit;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollEvent.loadPolls(page: $page, limit: $limit)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollEvent.loadPolls'))
      ..add(DiagnosticsProperty('page', page))
      ..add(DiagnosticsProperty('limit', limit));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadPollsImpl &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, page, limit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadPollsImplCopyWith<_$LoadPollsImpl> get copyWith =>
      __$$LoadPollsImplCopyWithImpl<_$LoadPollsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) {
    return loadPolls(page, limit);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) {
    return loadPolls?.call(page, limit);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) {
    if (loadPolls != null) {
      return loadPolls(page, limit);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) {
    return loadPolls(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) {
    return loadPolls?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) {
    if (loadPolls != null) {
      return loadPolls(this);
    }
    return orElse();
  }
}

abstract class LoadPolls implements PollEvent {
  const factory LoadPolls({required final int page, required final int limit}) =
      _$LoadPollsImpl;

  int get page;
  int get limit;
  @JsonKey(ignore: true)
  _$$LoadPollsImplCopyWith<_$LoadPollsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RefreshPollsImplCopyWith<$Res> {
  factory _$$RefreshPollsImplCopyWith(
          _$RefreshPollsImpl value, $Res Function(_$RefreshPollsImpl) then) =
      __$$RefreshPollsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RefreshPollsImplCopyWithImpl<$Res>
    extends _$PollEventCopyWithImpl<$Res, _$RefreshPollsImpl>
    implements _$$RefreshPollsImplCopyWith<$Res> {
  __$$RefreshPollsImplCopyWithImpl(
      _$RefreshPollsImpl _value, $Res Function(_$RefreshPollsImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$RefreshPollsImpl with DiagnosticableTreeMixin implements RefreshPolls {
  const _$RefreshPollsImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollEvent.refreshPolls()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'PollEvent.refreshPolls'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RefreshPollsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) {
    return refreshPolls();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) {
    return refreshPolls?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) {
    if (refreshPolls != null) {
      return refreshPolls();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) {
    return refreshPolls(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) {
    return refreshPolls?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) {
    if (refreshPolls != null) {
      return refreshPolls(this);
    }
    return orElse();
  }
}

abstract class RefreshPolls implements PollEvent {
  const factory RefreshPolls() = _$RefreshPollsImpl;
}

/// @nodoc
abstract class _$$LoadPollImplCopyWith<$Res> {
  factory _$$LoadPollImplCopyWith(
          _$LoadPollImpl value, $Res Function(_$LoadPollImpl) then) =
      __$$LoadPollImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String pollId});
}

/// @nodoc
class __$$LoadPollImplCopyWithImpl<$Res>
    extends _$PollEventCopyWithImpl<$Res, _$LoadPollImpl>
    implements _$$LoadPollImplCopyWith<$Res> {
  __$$LoadPollImplCopyWithImpl(
      _$LoadPollImpl _value, $Res Function(_$LoadPollImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollId = null,
  }) {
    return _then(_$LoadPollImpl(
      null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoadPollImpl with DiagnosticableTreeMixin implements LoadPoll {
  const _$LoadPollImpl(this.pollId);

  @override
  final String pollId;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollEvent.loadPoll(pollId: $pollId)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollEvent.loadPoll'))
      ..add(DiagnosticsProperty('pollId', pollId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadPollImpl &&
            (identical(other.pollId, pollId) || other.pollId == pollId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pollId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadPollImplCopyWith<_$LoadPollImpl> get copyWith =>
      __$$LoadPollImplCopyWithImpl<_$LoadPollImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) {
    return loadPoll(pollId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) {
    return loadPoll?.call(pollId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) {
    if (loadPoll != null) {
      return loadPoll(pollId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) {
    return loadPoll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) {
    return loadPoll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) {
    if (loadPoll != null) {
      return loadPoll(this);
    }
    return orElse();
  }
}

abstract class LoadPoll implements PollEvent {
  const factory LoadPoll(final String pollId) = _$LoadPollImpl;

  String get pollId;
  @JsonKey(ignore: true)
  _$$LoadPollImplCopyWith<_$LoadPollImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadMoreImplCopyWith<$Res> {
  factory _$$LoadMoreImplCopyWith(
          _$LoadMoreImpl value, $Res Function(_$LoadMoreImpl) then) =
      __$$LoadMoreImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int page, int limit});
}

/// @nodoc
class __$$LoadMoreImplCopyWithImpl<$Res>
    extends _$PollEventCopyWithImpl<$Res, _$LoadMoreImpl>
    implements _$$LoadMoreImplCopyWith<$Res> {
  __$$LoadMoreImplCopyWithImpl(
      _$LoadMoreImpl _value, $Res Function(_$LoadMoreImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_$LoadMoreImpl(
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LoadMoreImpl with DiagnosticableTreeMixin implements LoadMore {
  const _$LoadMoreImpl({required this.page, required this.limit});

  @override
  final int page;
  @override
  final int limit;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollEvent.loadMore(page: $page, limit: $limit)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollEvent.loadMore'))
      ..add(DiagnosticsProperty('page', page))
      ..add(DiagnosticsProperty('limit', limit));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadMoreImpl &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, page, limit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadMoreImplCopyWith<_$LoadMoreImpl> get copyWith =>
      __$$LoadMoreImplCopyWithImpl<_$LoadMoreImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) {
    return loadMore(page, limit);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) {
    return loadMore?.call(page, limit);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) {
    if (loadMore != null) {
      return loadMore(page, limit);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) {
    return loadMore(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) {
    return loadMore?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) {
    if (loadMore != null) {
      return loadMore(this);
    }
    return orElse();
  }
}

abstract class LoadMore implements PollEvent {
  const factory LoadMore({required final int page, required final int limit}) =
      _$LoadMoreImpl;

  int get page;
  int get limit;
  @JsonKey(ignore: true)
  _$$LoadMoreImplCopyWith<_$LoadMoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VoteImplCopyWith<$Res> {
  factory _$$VoteImplCopyWith(
          _$VoteImpl value, $Res Function(_$VoteImpl) then) =
      __$$VoteImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String pollId, String optionId});
}

/// @nodoc
class __$$VoteImplCopyWithImpl<$Res>
    extends _$PollEventCopyWithImpl<$Res, _$VoteImpl>
    implements _$$VoteImplCopyWith<$Res> {
  __$$VoteImplCopyWithImpl(_$VoteImpl _value, $Res Function(_$VoteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollId = null,
    Object? optionId = null,
  }) {
    return _then(_$VoteImpl(
      null == pollId
          ? _value.pollId
          : pollId // ignore: cast_nullable_to_non_nullable
              as String,
      null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$VoteImpl with DiagnosticableTreeMixin implements Vote {
  const _$VoteImpl(this.pollId, this.optionId);

  @override
  final String pollId;
  @override
  final String optionId;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollEvent.vote(pollId: $pollId, optionId: $optionId)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollEvent.vote'))
      ..add(DiagnosticsProperty('pollId', pollId))
      ..add(DiagnosticsProperty('optionId', optionId));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteImpl &&
            (identical(other.pollId, pollId) || other.pollId == pollId) &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pollId, optionId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteImplCopyWith<_$VoteImpl> get copyWith =>
      __$$VoteImplCopyWithImpl<_$VoteImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int page, int limit) loadPolls,
    required TResult Function() refreshPolls,
    required TResult Function(String pollId) loadPoll,
    required TResult Function(int page, int limit) loadMore,
    required TResult Function(String pollId, String optionId) vote,
  }) {
    return vote(pollId, optionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int page, int limit)? loadPolls,
    TResult? Function()? refreshPolls,
    TResult? Function(String pollId)? loadPoll,
    TResult? Function(int page, int limit)? loadMore,
    TResult? Function(String pollId, String optionId)? vote,
  }) {
    return vote?.call(pollId, optionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int page, int limit)? loadPolls,
    TResult Function()? refreshPolls,
    TResult Function(String pollId)? loadPoll,
    TResult Function(int page, int limit)? loadMore,
    TResult Function(String pollId, String optionId)? vote,
    required TResult orElse(),
  }) {
    if (vote != null) {
      return vote(pollId, optionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPolls value) loadPolls,
    required TResult Function(RefreshPolls value) refreshPolls,
    required TResult Function(LoadPoll value) loadPoll,
    required TResult Function(LoadMore value) loadMore,
    required TResult Function(Vote value) vote,
  }) {
    return vote(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPolls value)? loadPolls,
    TResult? Function(RefreshPolls value)? refreshPolls,
    TResult? Function(LoadPoll value)? loadPoll,
    TResult? Function(LoadMore value)? loadMore,
    TResult? Function(Vote value)? vote,
  }) {
    return vote?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPolls value)? loadPolls,
    TResult Function(RefreshPolls value)? refreshPolls,
    TResult Function(LoadPoll value)? loadPoll,
    TResult Function(LoadMore value)? loadMore,
    TResult Function(Vote value)? vote,
    required TResult orElse(),
  }) {
    if (vote != null) {
      return vote(this);
    }
    return orElse();
  }
}

abstract class Vote implements PollEvent {
  const factory Vote(final String pollId, final String optionId) = _$VoteImpl;

  String get pollId;
  String get optionId;
  @JsonKey(ignore: true)
  _$$VoteImplCopyWith<_$VoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PollState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Poll> polls, bool hasMore) loaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Poll> polls, bool hasMore)? loaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Poll> polls, bool hasMore)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(Loaded value) loaded,
    required TResult Function(Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(Loaded value)? loaded,
    TResult? Function(Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(Loaded value)? loaded,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollStateCopyWith<$Res> {
  factory $PollStateCopyWith(PollState value, $Res Function(PollState) then) =
      _$PollStateCopyWithImpl<$Res, PollState>;
}

/// @nodoc
class _$PollStateCopyWithImpl<$Res, $Val extends PollState>
    implements $PollStateCopyWith<$Res> {
  _$PollStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$PollStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$InitialImpl with DiagnosticableTreeMixin implements Initial {
  const _$InitialImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollState.initial()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'PollState.initial'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Poll> polls, bool hasMore) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Poll> polls, bool hasMore)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Poll> polls, bool hasMore)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(Loaded value) loaded,
    required TResult Function(Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(Loaded value)? loaded,
    TResult? Function(Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(Loaded value)? loaded,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements PollState {
  const factory Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$PollStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadingImpl with DiagnosticableTreeMixin implements Loading {
  const _$LoadingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollState.loading()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('type', 'PollState.loading'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Poll> polls, bool hasMore) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Poll> polls, bool hasMore)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Poll> polls, bool hasMore)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(Loaded value) loaded,
    required TResult Function(Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(Loaded value)? loaded,
    TResult? Function(Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(Loaded value)? loaded,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class Loading implements PollState {
  const factory Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Poll> polls, bool hasMore});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$PollStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? polls = null,
    Object? hasMore = null,
  }) {
    return _then(_$LoadedImpl(
      null == polls
          ? _value._polls
          : polls // ignore: cast_nullable_to_non_nullable
              as List<Poll>,
      null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$LoadedImpl with DiagnosticableTreeMixin implements Loaded {
  const _$LoadedImpl(final List<Poll> polls, this.hasMore) : _polls = polls;

  final List<Poll> _polls;
  @override
  List<Poll> get polls {
    if (_polls is EqualUnmodifiableListView) return _polls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_polls);
  }

  @override
  final bool hasMore;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollState.loaded(polls: $polls, hasMore: $hasMore)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollState.loaded'))
      ..add(DiagnosticsProperty('polls', polls))
      ..add(DiagnosticsProperty('hasMore', hasMore));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(other._polls, _polls) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_polls), hasMore);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Poll> polls, bool hasMore) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(polls, hasMore);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Poll> polls, bool hasMore)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(polls, hasMore);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Poll> polls, bool hasMore)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(polls, hasMore);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(Loaded value) loaded,
    required TResult Function(Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(Loaded value)? loaded,
    TResult? Function(Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(Loaded value)? loaded,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class Loaded implements PollState {
  const factory Loaded(final List<Poll> polls, final bool hasMore) =
      _$LoadedImpl;

  List<Poll> get polls;
  bool get hasMore;
  @JsonKey(ignore: true)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$PollStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl with DiagnosticableTreeMixin implements Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PollState.error(message: $message)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PollState.error'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Poll> polls, bool hasMore) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Poll> polls, bool hasMore)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Poll> polls, bool hasMore)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(Loading value) loading,
    required TResult Function(Loaded value) loaded,
    required TResult Function(Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(Loading value)? loading,
    TResult? Function(Loaded value)? loaded,
    TResult? Function(Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(Loading value)? loading,
    TResult Function(Loaded value)? loaded,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class Error implements PollState {
  const factory Error(final String message) = _$ErrorImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PositionModel {

 String get symbol; String get side; double get size; double get avgPrice; double get markPrice; double get unrealisedPnl; double get leverage;
/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionModelCopyWith<PositionModel> get copyWith => _$PositionModelCopyWithImpl<PositionModel>(this as PositionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.side, side) || other.side == side)&&(identical(other.size, size) || other.size == size)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.markPrice, markPrice) || other.markPrice == markPrice)&&(identical(other.unrealisedPnl, unrealisedPnl) || other.unrealisedPnl == unrealisedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,side,size,avgPrice,markPrice,unrealisedPnl,leverage);

@override
String toString() {
  return 'PositionModel(symbol: $symbol, side: $side, size: $size, avgPrice: $avgPrice, markPrice: $markPrice, unrealisedPnl: $unrealisedPnl, leverage: $leverage)';
}


}

/// @nodoc
abstract mixin class $PositionModelCopyWith<$Res>  {
  factory $PositionModelCopyWith(PositionModel value, $Res Function(PositionModel) _then) = _$PositionModelCopyWithImpl;
@useResult
$Res call({
 String symbol, String side, double size, double avgPrice, double markPrice, double unrealisedPnl, double leverage
});




}
/// @nodoc
class _$PositionModelCopyWithImpl<$Res>
    implements $PositionModelCopyWith<$Res> {
  _$PositionModelCopyWithImpl(this._self, this._then);

  final PositionModel _self;
  final $Res Function(PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? side = null,Object? size = null,Object? avgPrice = null,Object? markPrice = null,Object? unrealisedPnl = null,Object? leverage = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,avgPrice: null == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as double,markPrice: null == markPrice ? _self.markPrice : markPrice // ignore: cast_nullable_to_non_nullable
as double,unrealisedPnl: null == unrealisedPnl ? _self.unrealisedPnl : unrealisedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionModel].
extension PositionModelPatterns on PositionModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage)  $default,) {final _that = this;
switch (_that) {
case _PositionModel():
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage)?  $default,) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage);case _:
  return null;

}
}

}

/// @nodoc


class _PositionModel implements PositionModel {
  const _PositionModel({required this.symbol, required this.side, required this.size, required this.avgPrice, required this.markPrice, required this.unrealisedPnl, required this.leverage});
  

@override final  String symbol;
@override final  String side;
@override final  double size;
@override final  double avgPrice;
@override final  double markPrice;
@override final  double unrealisedPnl;
@override final  double leverage;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionModelCopyWith<_PositionModel> get copyWith => __$PositionModelCopyWithImpl<_PositionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.side, side) || other.side == side)&&(identical(other.size, size) || other.size == size)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.markPrice, markPrice) || other.markPrice == markPrice)&&(identical(other.unrealisedPnl, unrealisedPnl) || other.unrealisedPnl == unrealisedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,side,size,avgPrice,markPrice,unrealisedPnl,leverage);

@override
String toString() {
  return 'PositionModel(symbol: $symbol, side: $side, size: $size, avgPrice: $avgPrice, markPrice: $markPrice, unrealisedPnl: $unrealisedPnl, leverage: $leverage)';
}


}

/// @nodoc
abstract mixin class _$PositionModelCopyWith<$Res> implements $PositionModelCopyWith<$Res> {
  factory _$PositionModelCopyWith(_PositionModel value, $Res Function(_PositionModel) _then) = __$PositionModelCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String side, double size, double avgPrice, double markPrice, double unrealisedPnl, double leverage
});




}
/// @nodoc
class __$PositionModelCopyWithImpl<$Res>
    implements _$PositionModelCopyWith<$Res> {
  __$PositionModelCopyWithImpl(this._self, this._then);

  final _PositionModel _self;
  final $Res Function(_PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? side = null,Object? size = null,Object? avgPrice = null,Object? markPrice = null,Object? unrealisedPnl = null,Object? leverage = null,}) {
  return _then(_PositionModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,avgPrice: null == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as double,markPrice: null == markPrice ? _self.markPrice : markPrice // ignore: cast_nullable_to_non_nullable
as double,unrealisedPnl: null == unrealisedPnl ? _self.unrealisedPnl : unrealisedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

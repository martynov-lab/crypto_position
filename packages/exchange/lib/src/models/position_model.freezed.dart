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

 String get symbol; String get side; double get size; double get avgPrice; double get markPrice; double get unrealisedPnl; double get leverage;/// When the position was opened; anchors the fee/funding window.
 DateTime? get createdAt;/// Funding rate for the upcoming settlement, as a fraction (0.0001 = 0.01%).
 double? get fundingRate; DateTime? get nextFundingTime;/// Funding due at [nextFundingTime], signed from the account's point of
/// view: negative is paid out, positive is received. Computed inside each
/// exchange's repository, which knows how [side] is worded.
 double? get upcomingFundingUsd;/// Trading fees paid over this position's life, as a positive number.
 double? get paidCommission;/// Funding settled over this position's life, signed like
/// [upcomingFundingUsd]: negative is paid out, positive is received.
 double? get paidFunding;/// Start of the window [paidCommission] and [paidFunding] cover. Equals
/// [createdAt] for a position opened within [feesLookbackWindow]; for an
/// older one it is capped to that window, making the totals partial.
 DateTime? get feesSince;
/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionModelCopyWith<PositionModel> get copyWith => _$PositionModelCopyWithImpl<PositionModel>(this as PositionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.side, side) || other.side == side)&&(identical(other.size, size) || other.size == size)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.markPrice, markPrice) || other.markPrice == markPrice)&&(identical(other.unrealisedPnl, unrealisedPnl) || other.unrealisedPnl == unrealisedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.fundingRate, fundingRate) || other.fundingRate == fundingRate)&&(identical(other.nextFundingTime, nextFundingTime) || other.nextFundingTime == nextFundingTime)&&(identical(other.upcomingFundingUsd, upcomingFundingUsd) || other.upcomingFundingUsd == upcomingFundingUsd)&&(identical(other.paidCommission, paidCommission) || other.paidCommission == paidCommission)&&(identical(other.paidFunding, paidFunding) || other.paidFunding == paidFunding)&&(identical(other.feesSince, feesSince) || other.feesSince == feesSince));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,side,size,avgPrice,markPrice,unrealisedPnl,leverage,createdAt,fundingRate,nextFundingTime,upcomingFundingUsd,paidCommission,paidFunding,feesSince);

@override
String toString() {
  return 'PositionModel(symbol: $symbol, side: $side, size: $size, avgPrice: $avgPrice, markPrice: $markPrice, unrealisedPnl: $unrealisedPnl, leverage: $leverage, createdAt: $createdAt, fundingRate: $fundingRate, nextFundingTime: $nextFundingTime, upcomingFundingUsd: $upcomingFundingUsd, paidCommission: $paidCommission, paidFunding: $paidFunding, feesSince: $feesSince)';
}


}

/// @nodoc
abstract mixin class $PositionModelCopyWith<$Res>  {
  factory $PositionModelCopyWith(PositionModel value, $Res Function(PositionModel) _then) = _$PositionModelCopyWithImpl;
@useResult
$Res call({
 String symbol, String side, double size, double avgPrice, double markPrice, double unrealisedPnl, double leverage, DateTime? createdAt, double? fundingRate, DateTime? nextFundingTime, double? upcomingFundingUsd, double? paidCommission, double? paidFunding, DateTime? feesSince
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
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? side = null,Object? size = null,Object? avgPrice = null,Object? markPrice = null,Object? unrealisedPnl = null,Object? leverage = null,Object? createdAt = freezed,Object? fundingRate = freezed,Object? nextFundingTime = freezed,Object? upcomingFundingUsd = freezed,Object? paidCommission = freezed,Object? paidFunding = freezed,Object? feesSince = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,avgPrice: null == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as double,markPrice: null == markPrice ? _self.markPrice : markPrice // ignore: cast_nullable_to_non_nullable
as double,unrealisedPnl: null == unrealisedPnl ? _self.unrealisedPnl : unrealisedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fundingRate: freezed == fundingRate ? _self.fundingRate : fundingRate // ignore: cast_nullable_to_non_nullable
as double?,nextFundingTime: freezed == nextFundingTime ? _self.nextFundingTime : nextFundingTime // ignore: cast_nullable_to_non_nullable
as DateTime?,upcomingFundingUsd: freezed == upcomingFundingUsd ? _self.upcomingFundingUsd : upcomingFundingUsd // ignore: cast_nullable_to_non_nullable
as double?,paidCommission: freezed == paidCommission ? _self.paidCommission : paidCommission // ignore: cast_nullable_to_non_nullable
as double?,paidFunding: freezed == paidFunding ? _self.paidFunding : paidFunding // ignore: cast_nullable_to_non_nullable
as double?,feesSince: freezed == feesSince ? _self.feesSince : feesSince // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage,  DateTime? createdAt,  double? fundingRate,  DateTime? nextFundingTime,  double? upcomingFundingUsd,  double? paidCommission,  double? paidFunding,  DateTime? feesSince)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage,_that.createdAt,_that.fundingRate,_that.nextFundingTime,_that.upcomingFundingUsd,_that.paidCommission,_that.paidFunding,_that.feesSince);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage,  DateTime? createdAt,  double? fundingRate,  DateTime? nextFundingTime,  double? upcomingFundingUsd,  double? paidCommission,  double? paidFunding,  DateTime? feesSince)  $default,) {final _that = this;
switch (_that) {
case _PositionModel():
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage,_that.createdAt,_that.fundingRate,_that.nextFundingTime,_that.upcomingFundingUsd,_that.paidCommission,_that.paidFunding,_that.feesSince);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String side,  double size,  double avgPrice,  double markPrice,  double unrealisedPnl,  double leverage,  DateTime? createdAt,  double? fundingRate,  DateTime? nextFundingTime,  double? upcomingFundingUsd,  double? paidCommission,  double? paidFunding,  DateTime? feesSince)?  $default,) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.side,_that.size,_that.avgPrice,_that.markPrice,_that.unrealisedPnl,_that.leverage,_that.createdAt,_that.fundingRate,_that.nextFundingTime,_that.upcomingFundingUsd,_that.paidCommission,_that.paidFunding,_that.feesSince);case _:
  return null;

}
}

}

/// @nodoc


class _PositionModel extends PositionModel {
  const _PositionModel({required this.symbol, required this.side, required this.size, required this.avgPrice, required this.markPrice, required this.unrealisedPnl, required this.leverage, this.createdAt, this.fundingRate, this.nextFundingTime, this.upcomingFundingUsd, this.paidCommission, this.paidFunding, this.feesSince}): super._();
  

@override final  String symbol;
@override final  String side;
@override final  double size;
@override final  double avgPrice;
@override final  double markPrice;
@override final  double unrealisedPnl;
@override final  double leverage;
/// When the position was opened; anchors the fee/funding window.
@override final  DateTime? createdAt;
/// Funding rate for the upcoming settlement, as a fraction (0.0001 = 0.01%).
@override final  double? fundingRate;
@override final  DateTime? nextFundingTime;
/// Funding due at [nextFundingTime], signed from the account's point of
/// view: negative is paid out, positive is received. Computed inside each
/// exchange's repository, which knows how [side] is worded.
@override final  double? upcomingFundingUsd;
/// Trading fees paid over this position's life, as a positive number.
@override final  double? paidCommission;
/// Funding settled over this position's life, signed like
/// [upcomingFundingUsd]: negative is paid out, positive is received.
@override final  double? paidFunding;
/// Start of the window [paidCommission] and [paidFunding] cover. Equals
/// [createdAt] for a position opened within [feesLookbackWindow]; for an
/// older one it is capped to that window, making the totals partial.
@override final  DateTime? feesSince;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionModelCopyWith<_PositionModel> get copyWith => __$PositionModelCopyWithImpl<_PositionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.side, side) || other.side == side)&&(identical(other.size, size) || other.size == size)&&(identical(other.avgPrice, avgPrice) || other.avgPrice == avgPrice)&&(identical(other.markPrice, markPrice) || other.markPrice == markPrice)&&(identical(other.unrealisedPnl, unrealisedPnl) || other.unrealisedPnl == unrealisedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.fundingRate, fundingRate) || other.fundingRate == fundingRate)&&(identical(other.nextFundingTime, nextFundingTime) || other.nextFundingTime == nextFundingTime)&&(identical(other.upcomingFundingUsd, upcomingFundingUsd) || other.upcomingFundingUsd == upcomingFundingUsd)&&(identical(other.paidCommission, paidCommission) || other.paidCommission == paidCommission)&&(identical(other.paidFunding, paidFunding) || other.paidFunding == paidFunding)&&(identical(other.feesSince, feesSince) || other.feesSince == feesSince));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,side,size,avgPrice,markPrice,unrealisedPnl,leverage,createdAt,fundingRate,nextFundingTime,upcomingFundingUsd,paidCommission,paidFunding,feesSince);

@override
String toString() {
  return 'PositionModel(symbol: $symbol, side: $side, size: $size, avgPrice: $avgPrice, markPrice: $markPrice, unrealisedPnl: $unrealisedPnl, leverage: $leverage, createdAt: $createdAt, fundingRate: $fundingRate, nextFundingTime: $nextFundingTime, upcomingFundingUsd: $upcomingFundingUsd, paidCommission: $paidCommission, paidFunding: $paidFunding, feesSince: $feesSince)';
}


}

/// @nodoc
abstract mixin class _$PositionModelCopyWith<$Res> implements $PositionModelCopyWith<$Res> {
  factory _$PositionModelCopyWith(_PositionModel value, $Res Function(_PositionModel) _then) = __$PositionModelCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String side, double size, double avgPrice, double markPrice, double unrealisedPnl, double leverage, DateTime? createdAt, double? fundingRate, DateTime? nextFundingTime, double? upcomingFundingUsd, double? paidCommission, double? paidFunding, DateTime? feesSince
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
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? side = null,Object? size = null,Object? avgPrice = null,Object? markPrice = null,Object? unrealisedPnl = null,Object? leverage = null,Object? createdAt = freezed,Object? fundingRate = freezed,Object? nextFundingTime = freezed,Object? upcomingFundingUsd = freezed,Object? paidCommission = freezed,Object? paidFunding = freezed,Object? feesSince = freezed,}) {
  return _then(_PositionModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,avgPrice: null == avgPrice ? _self.avgPrice : avgPrice // ignore: cast_nullable_to_non_nullable
as double,markPrice: null == markPrice ? _self.markPrice : markPrice // ignore: cast_nullable_to_non_nullable
as double,unrealisedPnl: null == unrealisedPnl ? _self.unrealisedPnl : unrealisedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fundingRate: freezed == fundingRate ? _self.fundingRate : fundingRate // ignore: cast_nullable_to_non_nullable
as double?,nextFundingTime: freezed == nextFundingTime ? _self.nextFundingTime : nextFundingTime // ignore: cast_nullable_to_non_nullable
as DateTime?,upcomingFundingUsd: freezed == upcomingFundingUsd ? _self.upcomingFundingUsd : upcomingFundingUsd // ignore: cast_nullable_to_non_nullable
as double?,paidCommission: freezed == paidCommission ? _self.paidCommission : paidCommission // ignore: cast_nullable_to_non_nullable
as double?,paidFunding: freezed == paidFunding ? _self.paidFunding : paidFunding // ignore: cast_nullable_to_non_nullable
as double?,feesSince: freezed == feesSince ? _self.feesSince : feesSince // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

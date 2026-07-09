// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'closed_trade_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClosedTradeModel {

 String get symbol; String get orderId; String get side; double get qty; double get orderPrice; String get orderType; double get avgEntryPrice; double get avgExitPrice; double get closedPnl; double get leverage; double get cumEntryValue; double get cumExitValue; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ClosedTradeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClosedTradeModelCopyWith<ClosedTradeModel> get copyWith => _$ClosedTradeModelCopyWithImpl<ClosedTradeModel>(this as ClosedTradeModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClosedTradeModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.orderPrice, orderPrice) || other.orderPrice == orderPrice)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.avgEntryPrice, avgEntryPrice) || other.avgEntryPrice == avgEntryPrice)&&(identical(other.avgExitPrice, avgExitPrice) || other.avgExitPrice == avgExitPrice)&&(identical(other.closedPnl, closedPnl) || other.closedPnl == closedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage)&&(identical(other.cumEntryValue, cumEntryValue) || other.cumEntryValue == cumEntryValue)&&(identical(other.cumExitValue, cumExitValue) || other.cumExitValue == cumExitValue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,orderId,side,qty,orderPrice,orderType,avgEntryPrice,avgExitPrice,closedPnl,leverage,cumEntryValue,cumExitValue,createdAt,updatedAt);

@override
String toString() {
  return 'ClosedTradeModel(symbol: $symbol, orderId: $orderId, side: $side, qty: $qty, orderPrice: $orderPrice, orderType: $orderType, avgEntryPrice: $avgEntryPrice, avgExitPrice: $avgExitPrice, closedPnl: $closedPnl, leverage: $leverage, cumEntryValue: $cumEntryValue, cumExitValue: $cumExitValue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ClosedTradeModelCopyWith<$Res>  {
  factory $ClosedTradeModelCopyWith(ClosedTradeModel value, $Res Function(ClosedTradeModel) _then) = _$ClosedTradeModelCopyWithImpl;
@useResult
$Res call({
 String symbol, String orderId, String side, double qty, double orderPrice, String orderType, double avgEntryPrice, double avgExitPrice, double closedPnl, double leverage, double cumEntryValue, double cumExitValue, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ClosedTradeModelCopyWithImpl<$Res>
    implements $ClosedTradeModelCopyWith<$Res> {
  _$ClosedTradeModelCopyWithImpl(this._self, this._then);

  final ClosedTradeModel _self;
  final $Res Function(ClosedTradeModel) _then;

/// Create a copy of ClosedTradeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? orderId = null,Object? side = null,Object? qty = null,Object? orderPrice = null,Object? orderType = null,Object? avgEntryPrice = null,Object? avgExitPrice = null,Object? closedPnl = null,Object? leverage = null,Object? cumEntryValue = null,Object? cumExitValue = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,orderPrice: null == orderPrice ? _self.orderPrice : orderPrice // ignore: cast_nullable_to_non_nullable
as double,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,avgEntryPrice: null == avgEntryPrice ? _self.avgEntryPrice : avgEntryPrice // ignore: cast_nullable_to_non_nullable
as double,avgExitPrice: null == avgExitPrice ? _self.avgExitPrice : avgExitPrice // ignore: cast_nullable_to_non_nullable
as double,closedPnl: null == closedPnl ? _self.closedPnl : closedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,cumEntryValue: null == cumEntryValue ? _self.cumEntryValue : cumEntryValue // ignore: cast_nullable_to_non_nullable
as double,cumExitValue: null == cumExitValue ? _self.cumExitValue : cumExitValue // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ClosedTradeModel].
extension ClosedTradeModelPatterns on ClosedTradeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClosedTradeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClosedTradeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClosedTradeModel value)  $default,){
final _that = this;
switch (_that) {
case _ClosedTradeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClosedTradeModel value)?  $default,){
final _that = this;
switch (_that) {
case _ClosedTradeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String orderId,  String side,  double qty,  double orderPrice,  String orderType,  double avgEntryPrice,  double avgExitPrice,  double closedPnl,  double leverage,  double cumEntryValue,  double cumExitValue,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClosedTradeModel() when $default != null:
return $default(_that.symbol,_that.orderId,_that.side,_that.qty,_that.orderPrice,_that.orderType,_that.avgEntryPrice,_that.avgExitPrice,_that.closedPnl,_that.leverage,_that.cumEntryValue,_that.cumExitValue,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String orderId,  String side,  double qty,  double orderPrice,  String orderType,  double avgEntryPrice,  double avgExitPrice,  double closedPnl,  double leverage,  double cumEntryValue,  double cumExitValue,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ClosedTradeModel():
return $default(_that.symbol,_that.orderId,_that.side,_that.qty,_that.orderPrice,_that.orderType,_that.avgEntryPrice,_that.avgExitPrice,_that.closedPnl,_that.leverage,_that.cumEntryValue,_that.cumExitValue,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String orderId,  String side,  double qty,  double orderPrice,  String orderType,  double avgEntryPrice,  double avgExitPrice,  double closedPnl,  double leverage,  double cumEntryValue,  double cumExitValue,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ClosedTradeModel() when $default != null:
return $default(_that.symbol,_that.orderId,_that.side,_that.qty,_that.orderPrice,_that.orderType,_that.avgEntryPrice,_that.avgExitPrice,_that.closedPnl,_that.leverage,_that.cumEntryValue,_that.cumExitValue,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ClosedTradeModel extends ClosedTradeModel {
  const _ClosedTradeModel({required this.symbol, required this.orderId, required this.side, required this.qty, required this.orderPrice, required this.orderType, required this.avgEntryPrice, required this.avgExitPrice, required this.closedPnl, required this.leverage, required this.cumEntryValue, required this.cumExitValue, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String symbol;
@override final  String orderId;
@override final  String side;
@override final  double qty;
@override final  double orderPrice;
@override final  String orderType;
@override final  double avgEntryPrice;
@override final  double avgExitPrice;
@override final  double closedPnl;
@override final  double leverage;
@override final  double cumEntryValue;
@override final  double cumExitValue;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ClosedTradeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClosedTradeModelCopyWith<_ClosedTradeModel> get copyWith => __$ClosedTradeModelCopyWithImpl<_ClosedTradeModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClosedTradeModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.orderPrice, orderPrice) || other.orderPrice == orderPrice)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.avgEntryPrice, avgEntryPrice) || other.avgEntryPrice == avgEntryPrice)&&(identical(other.avgExitPrice, avgExitPrice) || other.avgExitPrice == avgExitPrice)&&(identical(other.closedPnl, closedPnl) || other.closedPnl == closedPnl)&&(identical(other.leverage, leverage) || other.leverage == leverage)&&(identical(other.cumEntryValue, cumEntryValue) || other.cumEntryValue == cumEntryValue)&&(identical(other.cumExitValue, cumExitValue) || other.cumExitValue == cumExitValue)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,orderId,side,qty,orderPrice,orderType,avgEntryPrice,avgExitPrice,closedPnl,leverage,cumEntryValue,cumExitValue,createdAt,updatedAt);

@override
String toString() {
  return 'ClosedTradeModel(symbol: $symbol, orderId: $orderId, side: $side, qty: $qty, orderPrice: $orderPrice, orderType: $orderType, avgEntryPrice: $avgEntryPrice, avgExitPrice: $avgExitPrice, closedPnl: $closedPnl, leverage: $leverage, cumEntryValue: $cumEntryValue, cumExitValue: $cumExitValue, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ClosedTradeModelCopyWith<$Res> implements $ClosedTradeModelCopyWith<$Res> {
  factory _$ClosedTradeModelCopyWith(_ClosedTradeModel value, $Res Function(_ClosedTradeModel) _then) = __$ClosedTradeModelCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String orderId, String side, double qty, double orderPrice, String orderType, double avgEntryPrice, double avgExitPrice, double closedPnl, double leverage, double cumEntryValue, double cumExitValue, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ClosedTradeModelCopyWithImpl<$Res>
    implements _$ClosedTradeModelCopyWith<$Res> {
  __$ClosedTradeModelCopyWithImpl(this._self, this._then);

  final _ClosedTradeModel _self;
  final $Res Function(_ClosedTradeModel) _then;

/// Create a copy of ClosedTradeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? orderId = null,Object? side = null,Object? qty = null,Object? orderPrice = null,Object? orderType = null,Object? avgEntryPrice = null,Object? avgExitPrice = null,Object? closedPnl = null,Object? leverage = null,Object? cumEntryValue = null,Object? cumExitValue = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ClosedTradeModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as double,orderPrice: null == orderPrice ? _self.orderPrice : orderPrice // ignore: cast_nullable_to_non_nullable
as double,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,avgEntryPrice: null == avgEntryPrice ? _self.avgEntryPrice : avgEntryPrice // ignore: cast_nullable_to_non_nullable
as double,avgExitPrice: null == avgExitPrice ? _self.avgExitPrice : avgExitPrice // ignore: cast_nullable_to_non_nullable
as double,closedPnl: null == closedPnl ? _self.closedPnl : closedPnl // ignore: cast_nullable_to_non_nullable
as double,leverage: null == leverage ? _self.leverage : leverage // ignore: cast_nullable_to_non_nullable
as double,cumEntryValue: null == cumEntryValue ? _self.cumEntryValue : cumEntryValue // ignore: cast_nullable_to_non_nullable
as double,cumExitValue: null == cumExitValue ? _self.cumExitValue : cumExitValue // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

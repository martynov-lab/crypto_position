// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_balance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalletBalanceModel {

 String get accountType; double get totalEquity; double get totalWalletBalance; List<CoinBalanceModel> get coins;
/// Create a copy of WalletBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletBalanceModelCopyWith<WalletBalanceModel> get copyWith => _$WalletBalanceModelCopyWithImpl<WalletBalanceModel>(this as WalletBalanceModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletBalanceModel&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.totalWalletBalance, totalWalletBalance) || other.totalWalletBalance == totalWalletBalance)&&const DeepCollectionEquality().equals(other.coins, coins));
}


@override
int get hashCode => Object.hash(runtimeType,accountType,totalEquity,totalWalletBalance,const DeepCollectionEquality().hash(coins));

@override
String toString() {
  return 'WalletBalanceModel(accountType: $accountType, totalEquity: $totalEquity, totalWalletBalance: $totalWalletBalance, coins: $coins)';
}


}

/// @nodoc
abstract mixin class $WalletBalanceModelCopyWith<$Res>  {
  factory $WalletBalanceModelCopyWith(WalletBalanceModel value, $Res Function(WalletBalanceModel) _then) = _$WalletBalanceModelCopyWithImpl;
@useResult
$Res call({
 String accountType, double totalEquity, double totalWalletBalance, List<CoinBalanceModel> coins
});




}
/// @nodoc
class _$WalletBalanceModelCopyWithImpl<$Res>
    implements $WalletBalanceModelCopyWith<$Res> {
  _$WalletBalanceModelCopyWithImpl(this._self, this._then);

  final WalletBalanceModel _self;
  final $Res Function(WalletBalanceModel) _then;

/// Create a copy of WalletBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountType = null,Object? totalEquity = null,Object? totalWalletBalance = null,Object? coins = null,}) {
  return _then(_self.copyWith(
accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as double,totalWalletBalance: null == totalWalletBalance ? _self.totalWalletBalance : totalWalletBalance // ignore: cast_nullable_to_non_nullable
as double,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as List<CoinBalanceModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletBalanceModel].
extension WalletBalanceModelPatterns on WalletBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _WalletBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _WalletBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountType,  double totalEquity,  double totalWalletBalance,  List<CoinBalanceModel> coins)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletBalanceModel() when $default != null:
return $default(_that.accountType,_that.totalEquity,_that.totalWalletBalance,_that.coins);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountType,  double totalEquity,  double totalWalletBalance,  List<CoinBalanceModel> coins)  $default,) {final _that = this;
switch (_that) {
case _WalletBalanceModel():
return $default(_that.accountType,_that.totalEquity,_that.totalWalletBalance,_that.coins);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountType,  double totalEquity,  double totalWalletBalance,  List<CoinBalanceModel> coins)?  $default,) {final _that = this;
switch (_that) {
case _WalletBalanceModel() when $default != null:
return $default(_that.accountType,_that.totalEquity,_that.totalWalletBalance,_that.coins);case _:
  return null;

}
}

}

/// @nodoc


class _WalletBalanceModel implements WalletBalanceModel {
  const _WalletBalanceModel({required this.accountType, required this.totalEquity, required this.totalWalletBalance, required final  List<CoinBalanceModel> coins}): _coins = coins;
  

@override final  String accountType;
@override final  double totalEquity;
@override final  double totalWalletBalance;
 final  List<CoinBalanceModel> _coins;
@override List<CoinBalanceModel> get coins {
  if (_coins is EqualUnmodifiableListView) return _coins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coins);
}


/// Create a copy of WalletBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletBalanceModelCopyWith<_WalletBalanceModel> get copyWith => __$WalletBalanceModelCopyWithImpl<_WalletBalanceModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletBalanceModel&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.totalWalletBalance, totalWalletBalance) || other.totalWalletBalance == totalWalletBalance)&&const DeepCollectionEquality().equals(other._coins, _coins));
}


@override
int get hashCode => Object.hash(runtimeType,accountType,totalEquity,totalWalletBalance,const DeepCollectionEquality().hash(_coins));

@override
String toString() {
  return 'WalletBalanceModel(accountType: $accountType, totalEquity: $totalEquity, totalWalletBalance: $totalWalletBalance, coins: $coins)';
}


}

/// @nodoc
abstract mixin class _$WalletBalanceModelCopyWith<$Res> implements $WalletBalanceModelCopyWith<$Res> {
  factory _$WalletBalanceModelCopyWith(_WalletBalanceModel value, $Res Function(_WalletBalanceModel) _then) = __$WalletBalanceModelCopyWithImpl;
@override @useResult
$Res call({
 String accountType, double totalEquity, double totalWalletBalance, List<CoinBalanceModel> coins
});




}
/// @nodoc
class __$WalletBalanceModelCopyWithImpl<$Res>
    implements _$WalletBalanceModelCopyWith<$Res> {
  __$WalletBalanceModelCopyWithImpl(this._self, this._then);

  final _WalletBalanceModel _self;
  final $Res Function(_WalletBalanceModel) _then;

/// Create a copy of WalletBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountType = null,Object? totalEquity = null,Object? totalWalletBalance = null,Object? coins = null,}) {
  return _then(_WalletBalanceModel(
accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as double,totalWalletBalance: null == totalWalletBalance ? _self.totalWalletBalance : totalWalletBalance // ignore: cast_nullable_to_non_nullable
as double,coins: null == coins ? _self._coins : coins // ignore: cast_nullable_to_non_nullable
as List<CoinBalanceModel>,
  ));
}


}

/// @nodoc
mixin _$CoinBalanceModel {

 String get coin; double get equity; double get walletBalance; double get usdValue;
/// Create a copy of CoinBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoinBalanceModelCopyWith<CoinBalanceModel> get copyWith => _$CoinBalanceModelCopyWithImpl<CoinBalanceModel>(this as CoinBalanceModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoinBalanceModel&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.equity, equity) || other.equity == equity)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.usdValue, usdValue) || other.usdValue == usdValue));
}


@override
int get hashCode => Object.hash(runtimeType,coin,equity,walletBalance,usdValue);

@override
String toString() {
  return 'CoinBalanceModel(coin: $coin, equity: $equity, walletBalance: $walletBalance, usdValue: $usdValue)';
}


}

/// @nodoc
abstract mixin class $CoinBalanceModelCopyWith<$Res>  {
  factory $CoinBalanceModelCopyWith(CoinBalanceModel value, $Res Function(CoinBalanceModel) _then) = _$CoinBalanceModelCopyWithImpl;
@useResult
$Res call({
 String coin, double equity, double walletBalance, double usdValue
});




}
/// @nodoc
class _$CoinBalanceModelCopyWithImpl<$Res>
    implements $CoinBalanceModelCopyWith<$Res> {
  _$CoinBalanceModelCopyWithImpl(this._self, this._then);

  final CoinBalanceModel _self;
  final $Res Function(CoinBalanceModel) _then;

/// Create a copy of CoinBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? coin = null,Object? equity = null,Object? walletBalance = null,Object? usdValue = null,}) {
  return _then(_self.copyWith(
coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as String,equity: null == equity ? _self.equity : equity // ignore: cast_nullable_to_non_nullable
as double,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,usdValue: null == usdValue ? _self.usdValue : usdValue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CoinBalanceModel].
extension CoinBalanceModelPatterns on CoinBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoinBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoinBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoinBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _CoinBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoinBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _CoinBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String coin,  double equity,  double walletBalance,  double usdValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoinBalanceModel() when $default != null:
return $default(_that.coin,_that.equity,_that.walletBalance,_that.usdValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String coin,  double equity,  double walletBalance,  double usdValue)  $default,) {final _that = this;
switch (_that) {
case _CoinBalanceModel():
return $default(_that.coin,_that.equity,_that.walletBalance,_that.usdValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String coin,  double equity,  double walletBalance,  double usdValue)?  $default,) {final _that = this;
switch (_that) {
case _CoinBalanceModel() when $default != null:
return $default(_that.coin,_that.equity,_that.walletBalance,_that.usdValue);case _:
  return null;

}
}

}

/// @nodoc


class _CoinBalanceModel implements CoinBalanceModel {
  const _CoinBalanceModel({required this.coin, required this.equity, required this.walletBalance, required this.usdValue});
  

@override final  String coin;
@override final  double equity;
@override final  double walletBalance;
@override final  double usdValue;

/// Create a copy of CoinBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoinBalanceModelCopyWith<_CoinBalanceModel> get copyWith => __$CoinBalanceModelCopyWithImpl<_CoinBalanceModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoinBalanceModel&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.equity, equity) || other.equity == equity)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.usdValue, usdValue) || other.usdValue == usdValue));
}


@override
int get hashCode => Object.hash(runtimeType,coin,equity,walletBalance,usdValue);

@override
String toString() {
  return 'CoinBalanceModel(coin: $coin, equity: $equity, walletBalance: $walletBalance, usdValue: $usdValue)';
}


}

/// @nodoc
abstract mixin class _$CoinBalanceModelCopyWith<$Res> implements $CoinBalanceModelCopyWith<$Res> {
  factory _$CoinBalanceModelCopyWith(_CoinBalanceModel value, $Res Function(_CoinBalanceModel) _then) = __$CoinBalanceModelCopyWithImpl;
@override @useResult
$Res call({
 String coin, double equity, double walletBalance, double usdValue
});




}
/// @nodoc
class __$CoinBalanceModelCopyWithImpl<$Res>
    implements _$CoinBalanceModelCopyWith<$Res> {
  __$CoinBalanceModelCopyWithImpl(this._self, this._then);

  final _CoinBalanceModel _self;
  final $Res Function(_CoinBalanceModel) _then;

/// Create a copy of CoinBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? coin = null,Object? equity = null,Object? walletBalance = null,Object? usdValue = null,}) {
  return _then(_CoinBalanceModel(
coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as String,equity: null == equity ? _self.equity : equity // ignore: cast_nullable_to_non_nullable
as double,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,usdValue: null == usdValue ? _self.usdValue : usdValue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

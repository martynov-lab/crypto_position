import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../domain/models/wallet_balance.dart';

class BybitRestClient {
  static const _baseUrl = 'https://api.bybit.com';

  final Dio _dio;
  final String apiKey;
  final String apiSecret;

  BybitRestClient({required this.apiKey, required this.apiSecret, Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  String _sign(String timestamp, String queryString) {
    final payload = '$timestamp$apiKey${20000}$queryString';
    final hmac = Hmac(sha256, utf8.encode(apiSecret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  Map<String, String> _authHeaders(String timestamp, String sign) => {
    'X-BAPI-API-KEY': apiKey,
    'X-BAPI-SIGN': sign,
    'X-BAPI-SIGN-TYPE': '2',
    'X-BAPI-TIMESTAMP': timestamp,
    'X-BAPI-RECV-WINDOW': '20000',
  };

  Future<WalletBalance> getWalletBalance({
    String accountType = 'UNIFIED',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final queryString = 'accountType=$accountType';
    final sign = _sign(timestamp, queryString);

    final response = await _dio.get(
      '/v5/account/wallet-balance',
      queryParameters: {'accountType': accountType},
      options: Options(headers: _authHeaders(timestamp, sign)),
    );

    final data = response.data as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    final list = result['list'] as List<dynamic>;
    if (list.isEmpty) {
      return WalletBalance(
        accountType: accountType,
        totalEquity: 0,
        totalWalletBalance: 0,
        coins: [],
      );
    }
    return WalletBalance.fromJson(list.first as Map<String, dynamic>);
  }
}

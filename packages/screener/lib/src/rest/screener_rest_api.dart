import 'package:core/core.dart';
import 'package:network/network.dart';

import '../models/client_config.dart';
import '../models/instrument_coverage.dart';
import '../models/summary_entry.dart';

/// Result of `POST /config/validate`.
class ConfigValidation {
  final bool valid;
  final String? error;

  const ConfigValidation({required this.valid, this.error});
}

/// The screener server's REST surface (guide §1, §4). All methods return
/// [Result] and never throw.
class ScreenerRestApi {
  final RestClient _client;

  const ScreenerRestApi(this._client);

  /// `GET /summary` — current best spread per instrument, highest net first.
  Future<Result<List<SummaryEntry>, Object>> fetchSummary() async {
    final result = await _client.get<List<Object?>>('/summary');
    return result.map(
      (rows) => rows
          .whereType<Map>()
          .map((e) => SummaryEntry.fromJson(e.cast<String, Object?>()))
          .toList(),
    );
  }

  /// `GET /instruments` — the full traded-instrument catalog (all coverage).
  Future<Result<List<InstrumentCoverage>, Object>> fetchInstruments() async {
    final result = await _client.get<List<Object?>>('/instruments');
    return result.map(
      (rows) => rows
          .whereType<Map>()
          .map((e) => InstrumentCoverage.fromJson(e.cast<String, Object?>()))
          .toList(),
    );
  }

  /// `POST /config/validate` — validate a config without subscribing.
  Future<Result<ConfigValidation, Object>> validateConfig(
    ClientConfig config,
  ) async {
    final result =
        await _client.post<Map<String, Object?>>(
      '/config/validate',
      body: config.toJson(),
    );
    return result.map(
      (json) => ConfigValidation(
        valid: json['valid'] == true,
        error: json['error']?.toString(),
      ),
    );
  }

  /// `GET /healthz` — liveness + instrument count.
  Future<Result<Map<String, Object?>, Object>> healthz() =>
      _client.get<Map<String, Object?>>('/healthz');
}

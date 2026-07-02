# REST API Infrastructure — Design

Date: 2026-07-02
Status: approved by user

## Goal

Implement the REST API layer structure from `rest_api_architecture.md`: a `RestClient`
wrapper over Dio returning `Result<T, Object>`, plus a reference feature module built
on a real Bybit endpoint. The existing `bybit` package is not modified.

## Packages

### `packages/core_shared`

Pure Dart, no dependencies.

- `Result<T, E>` sealed class with `Ok<T, E>` / `Err<T, E>` variants and
  `map`, `mapErr`, `fold` methods (document §4).

### `packages/network_shared`

Depends on `dio`, `core_shared`.

- `RestClient` — wrapper over Dio with `get`, `post`, `put`, `patch`, `delete`,
  `head`. All methods return `Future<Result<T, Object>>` and never throw (§3).
  Body is JSON-encoded via `jsonEncode`; `FormData` passed through as-is.
- Exception hierarchy (§3):
  - `RestClientException` (abstract base: `message`, `statusCode`, `cause`)
  - `ClientException`, `ConnectionException`, `CustomBackendException`
    (with `Map<String, Object?> error`), `InternalServerException`,
    `WrongResponseTypeException` (when `response.data is! T`).
  - `DioException` mapping: timeouts/connection errors → `ConnectionException`;
    response body is a Map → `CustomBackendException`; status ≥ 500 →
    `InternalServerException`; everything else → `ClientException`.
- `BaseUrlDioInterceptor` — sets `options.baseUrl` from a `Uri Function()` (§10.3).
- `createSharedHttpClient` — Dio factory with timeouts (§12, no Flutter-specific
  proxy/adapter logic).
- No `LoggerMixin`: the project has no `logging` package; errors propagate via `Result`.

### `packages/bybit_account_shared`

Reference feature module (§2, §16) over Bybit `GET /v5/account/wallet-balance`.
Depends on `core_shared`, `network_shared`, `json_annotation`, `freezed_annotation`;
dev: `build_runner`, `json_serializable`, `freezed`.

```
lib/src/
├── api/
│   ├── dto/wallet_balance_dto.dart      # @JsonSerializable(checked: true, createToJson: false)
│   ├── mappers/wallet_balance_mapper.dart  # extension WalletBalanceMapper on dto, toModel()
│   └── bybit_account_api.dart           # takes RestClient, returns Result<Dto, Object>
└── domain/
    ├── models/wallet_balance_model.dart # @freezed, domain types
    └── bybit_account_repository.dart    # takes Api, returns Result<Model, Object>
```

- DTO fields are `String` as Bybit returns them; the mapper parses to `double`.
  Decision: `double` instead of `Decimal` to avoid a new dependency (user approved).
- Api parses the Bybit envelope (`result.list[0]`) and returns
  `Result<WalletBalanceDto, Object>`; it does not call the mapper.
- Repository converts DTO → Model via the mapper extension.

## DI (app level)

In `lib/src/position_provider.dart` add providers:

```
Dio (BaseUrlDioInterceptor from BybitConfig, then BybitAuthInterceptor)
  → RestClient
  → BybitAccountRepository(BybitAccountApi(restClient))
```

Interceptor order matters: `BaseUrlDioInterceptor` must run **before**
`BybitAuthInterceptor` because the auth interceptor signs the final URL/params.

API keys are loaded asynchronously from `FlutterSecureStorage`, so a plain
`Provider<Dio>` at app level cannot be pre-authenticated. Following the existing
pattern (screens build Dio via `DioClientFactory` once keys are loaded), DI
provides a `BybitAccountRepositoryFactory`: given `apiKey`/`apiSecret`, it builds
`createSharedHttpClient()` + interceptors → `RestClient` →
`BybitAccountApi` → `BybitAccountRepository`. UI screens are not reworked.

## Verification

- `dart run build_runner build` succeeds in `bybit_account_shared`.
- `flutter analyze` clean.
- Unit tests: RestClient error mapping (stub `HttpClientAdapter`), success path,
  `WrongResponseTypeException`; mapper DTO → Model; Result `map`/`mapErr`/`fold`.

## Out of scope

- Migrating the existing `bybit` package.
- UI changes, `LocalizationDioInterceptor`, `RetryInterceptor`, auth-token refresh,
  `ProblemDetailsDto` (no RFC 7807 backend here).

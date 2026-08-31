# Architecture

The project follows the same Clean Architecture flow used by the previous app
on `main`:

```text
UI -> Cubit/BLoC -> Use case -> Repository -> Local/Remote data source
                                                |          |
                                              SQLite      Dio
```

## Main building blocks

- `lib/core`: environment, Dio, shared local storage, common BLoC observer.
- `lib/domain`: entities, repository contracts and shared use-case contracts.
- `lib/data`: local/remote data sources and repository implementations.
- `lib/features`: feature-specific data/domain/presentation code.
- `lib/injection_container.dart`: all runtime dependency registration with GetIt.

The Material Library is the reference implementation for local CRUD. It uses a
Cubit and use cases above the existing SQLite store. Push token registration is
the reference implementation for a remote flow: entity, repository, local
cache, Dio remote source and use case.

## Adding an API feature

1. Add an entity and repository contract under `domain` (or the feature domain).
2. Add JSON/SQLite models and data sources under `data`.
3. Implement the repository and map models to entities.
4. Add focused use cases, then consume them from a Cubit/BLoC.
5. Register every implementation in `injection_container.dart`.

`ApiClient` exposes typed `get`, `post`, `put` and `delete` calls. Its Dio
instance automatically adds `Authorization: Bearer <token>` when
`StorageKeys.authToken` exists in `LocalStorage`. API failures are normalized to
`ApiException`.

## Environment values

Edit `.env.dev` and `.env.prod`:

- `API_BASE_URL`: base URL for Dio.
- `API_TIMEOUT_MS`: connect/send/receive timeout.
- `FCM_TOKEN_ENDPOINT`: backend path that receives
  `{deviceRegistrationId, platform}`. Leave empty until that API exists.

The selected entry point loads the matching file before dependency injection.

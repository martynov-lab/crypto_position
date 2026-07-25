# Android-сборка в GitHub Actions с отправкой в Telegram

Workflow: [`.github/workflows/android-telegram.yml`](../.github/workflows/android-telegram.yml).
Собирает release-APK, подписывает его боевым ключом и отправляет файл в Telegram-бота.

## Когда запускается

- вручную — вкладка Actions → «Android APK to Telegram» → Run workflow;
- автоматически — на пуш тега `v*`:

  ```powershell
  git tag v0.1.1
  git push origin v0.1.1
  ```

## Что уходит в бота

`flutter build apk --release --split-per-abi` даёт три APK, в бота уходит только
`arm64-v8a` (~20 МБ) под именем `cryptovit-<версия>-<ref>-arm64.apk`.

Универсальный APK весит ~62 МБ, а Bot API не принимает файлы больше 50 МБ —
поэтому split, а не один файл. arm64 покрывает все актуальные телефоны;
`armeabi-v7a` (устройства до ~2017) и `x86_64` (эмулятор) остаются в артефактах
сборки, но не отправляются.

## Секреты репозитория

Settings → Secrets and variables → Actions → New repository secret.

| Секрет                       | Значение                                                        |
| ---------------------------- | --------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`    | keystore, закодированный в base64 (см. ниже)                     |
| `ANDROID_KEYSTORE_PASSWORD`  | пароль хранилища                                                 |
| `ANDROID_KEY_ALIAS`          | `upload`                                                          |
| `ANDROID_KEY_PASSWORD`       | пароль ключа (совпадает с паролем хранилища)                     |
| `TELEGRAM_BOT_TOKEN`         | токен бота от @BotFather                                          |
| `TELEGRAM_CHAT_ID`           | id чата, куда слать APK                                           |
| `ARB_TOKEN`                  | токен сервера скринера (`ARB_AUTH_TOKEN` из env сервера)          |
| `ARB_HOST`                   | необязательный; без него берётся `arovit-screener.duckdns.org`    |

`ARB_HOST`/`ARB_TOKEN` передаются в сборку через `--dart-define`, как и в
[Windows-сборке](../installer/README.md). Токен вшивается в APK открытым
текстом — раздача APK равна раздаче токена.

### Как получить chat_id

Написать боту любое сообщение и открыть:

```
https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
```

Взять `result[].message.chat.id`. Для личного чата это положительное число,
для группы — отрицательное (`-100…`). Бот должен состоять в группе.

### Как получить base64 keystore

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\keystores\cryptovit-upload.jks")) | Set-Clipboard
```

## Подпись

[`android/app/build.gradle.kts`](../android/app/build.gradle.kts) читает
`android/key.properties`; если файла нет — release подписывается debug-ключом,
как раньше.

- Локально `key.properties` указывает на keystore вне репозитория
  (`%USERPROFILE%\keystores\cryptovit-upload.jks`).
- На CI оба файла создаются из секретов и живут только внутри runner'а.

`key.properties` и `*.jks` в `.gitignore` — в репозиторий они попасть не должны.

**Keystore нельзя терять.** Он один на все будущие сборки: APK, подписанный
другим ключом, не встанет поверх установленного, а в Google Play приложение с
новым ключом не примут. Копию `cryptovit-upload.jks` и пароль стоит держать в
менеджере паролей.

## Известные ограничения

- `applicationId` остался `com.example.crypto_position`. Для публикации в Google
  Play его нужно сменить, но после смены приложение считается новым: обновление
  поверх установленного не встанет.
- Тесты в workflow не запускаются — только сборка.

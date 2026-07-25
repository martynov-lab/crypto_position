# Релизные сборки

Оба артефакта складываются в `build/release/`:

- `Cryptovit-<версия>-windows-x64-setup.exe` — установщик Windows (Inno Setup 6)
- `Cryptovit-<версия>-android.apk` — Android APK

## Разовая подготовка

1. Установить Inno Setup 6 (нужен только для Windows-установщика):

   ```powershell
   winget install --id JRSoftware.InnoSetup --source winget
   ```

   winget ставит его в `%LOCALAPPDATA%\Programs\Inno Setup 6`;
   `build_installer.ps1` ищет `ISCC.exe` там, а также в `Program Files` и `Program Files (x86)`.

2. Создать `installer\build.env` — адрес и токен сервера скринера:

   ```powershell
   Copy-Item installer\build.env.example installer\build.env
   ```

   и вписать `ARB_TOKEN` (значение `ARB_AUTH_TOKEN` из env сервера).
   Файл в `.gitignore` — токен не должен попадать в репозиторий.

## Настройки сервера

`build.env` читается построчно как `KEY=VALUE` и целиком передаётся в сборку
через `--dart-define` — одинаково для Windows и Android. Приложение читает их в
[`ScreenerConfig`](../packages/screener/lib/src/screener_config.dart):

| Ключ        | Назначение                                                        |
| ----------- | ----------------------------------------------------------------- |
| `ARB_HOST`  | Хост сервера скринера, можно с портом (`127.0.0.1:8080` для локального) |
| `ARB_TOKEN` | Токен авторизации; пустой = запросы без токена (локальный сервер без auth) |

Без `build.env` скрипты откажутся собирать: иначе получилась бы сборка,
которая молча не ходит на сервер.

## Сборка

Из корня репозитория — обе платформы сразу:

```powershell
pwsh scripts\build_release.ps1
```

Только одна платформа:

```powershell
pwsh scripts\build_release.ps1 -Target windows
pwsh scripts\build_release.ps1 -Target android
```

Что происходит:

- **Windows** — делегируется в `installer\build_installer.ps1`: тот находит `ISCC.exe`,
  берёт версию из `pubspec.yaml`, разворачивает `build.env` в `--dart-define`,
  запускает `flutter build windows --release` и компилирует `cryptovit.iss`.
- **Android** — `flutter build apk --release` с теми же `--dart-define`, затем APK
  копируется из `build\app\outputs\flutter-apk\` в `build\release\` под именем с версией.

Windows-установщик можно собрать и напрямую, минуя общий скрипт:

```powershell
pwsh installer\build_installer.ps1              # полная сборка
pwsh installer\build_installer.ps1 -SkipFlutterBuild   # если Release уже свежий
```

## Установка Windows

Запустить `Cryptovit-<версия>-windows-x64-setup.exe`.

- Требует прав администратора (UAC), ставит в `C:\Program Files\Cryptovit`.
- Язык мастера: русский или английский.
- Ярлык в меню Пуск создаётся всегда, на рабочем столе — по галочке.
- Удаление — через «Установленные приложения» или `unins000.exe` в папке установки.

Повторный запуск установщика новой версии обновляет установленную поверх:
`AppId` в `cryptovit.iss` фиксирован, менять его нельзя, иначе Windows посчитает
сборку отдельным приложением и рядом появится вторая установка.

Пользовательские данные (`shared_preferences`, ключи бирж) лежат в
`%APPDATA%\Cryptovit\Cryptovit\` — вне папки установки, поэтому обновление и
удаление их не трогают. Путь собирается из `CompanyName` и `ProductName` в
[`windows/runner/Runner.rc`](../windows/runner/Runner.rc): менять эти строки нельзя,
иначе приложение начнёт смотреть в новую пустую папку.

## Смена версии

Версия берётся только из `pubspec.yaml`:

```yaml
version: 0.1.0
```

Правится там, в `.iss` дублировать не нужно.

## Ограничения текущих сборок

- **Visual C++ Redistributable не входит в Windows-пакет.** На машине, где собирался
  проект, он уже есть, но на чистой Windows приложение не стартует. Для раздачи нужно
  добавить в секцию `[Files]` файлы `msvcp140.dll`, `vcruntime140.dll`,
  `vcruntime140_1.dll` рядом с exe.
- **Установщик не подписан** — на чужой машине SmartScreen покажет предупреждение
  «Windows защитила ваш компьютер». Лечится только сертификатом для подписи кода.
- **APK подписан debug-ключом** — в `android/app/build.gradle.kts` для release стоит
  `signingConfig = signingConfigs.getByName("debug")` (заглушка Flutter). Для локальной
  установки годится, но ключ привязан к `~/.android/debug.keystore`: со сборки на другой
  машине обновление поверх не встанет, и в Play такой APK не загрузить.
- **`ARB_TOKEN` вшивается в бинарник в открытом виде** — `--dart-define` не шифрует,
  строка достаётся из `data\app.so` (и из APK) обычным поиском. Считать сборку носителем
  секрета нельзя: у всех, кому она роздана, есть и токен сервера.
- Windows собирается только под x64; APK — универсальный (fat), без разбивки по ABI.

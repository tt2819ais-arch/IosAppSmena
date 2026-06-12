# Смена — учёт смен и зарплаты (iOS)

Нативное iOS-приложение на **SwiftUI** для учёта рабочих смен, доходов/расходов,
денежной цели и графика выплат зарплаты (2 раза в месяц).

## Возможности
- **Смены** — дата, время начала/конца, ставка ₽/час, перерыв. Часы и заработок считаются автоматически.
- **Доходы / расходы** — любые дополнительные суммы с заметкой и датой.
- **Денежная цель** — кольцо прогресса: сколько заработано и сколько осталось.
- **При добавлении смены** — сразу видно, сколько уже заработано и сколько осталось до цели.
- **График выплат** — 2 раза в месяц (по умолчанию 10 и 25 числа), ближайшая выплата, сумма за период, диаграмма по датам.
- **Настройки** — валюта, ставка по умолчанию, дни выплат, цель, тема и акцентный цвет.
- Анимация запуска ~0.6 сек, тёмная/светлая тема, хранение данных локально (без интернета).

## Сборка `.ipa` (без подписи) через GitHub Actions

> ⚠️ GitHub-приложение не может само создать файл в `.github/workflows/`.
> Поэтому **создай workflow вручную один раз** (займёт минуту), дальше всё автоматически.

### Как создать workflow
1. Открой репозиторий на github.com → кнопка **Add file** → **Create new file**.
2. В поле имени файла впиши: `.github/workflows/ios-ipa.yml`
3. Вставь содержимое целиком (оно лежит также в файле `ci-workflow.yml` в корне репозитория):

```yaml
name: Build IPA (unsigned)

on:
  push:
    branches: [ main, master, "capy/**" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    env:
      BUNDLE_ID: com.smena.tracker
      SCHEME: Smena
      PROJECT: Smena.xcodeproj
    steps:
      - uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build unsigned .app
        run: |
          set -eo pipefail
          xcodebuild \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build/dd \
            PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGN_ENTITLEMENTS="" \
            CODE_SIGN_STYLE=Manual \
            DEVELOPMENT_TEAM="" \
            PROVISIONING_PROFILE_SPECIFIER="" \
            ENABLE_BITCODE=NO \
            build

      - name: Package IPA
        run: |
          set -eo pipefail
          APP_PATH=$(find build/dd/Build/Products/Release-iphoneos -maxdepth 2 -name '*.app' -type d | head -n1)
          if [ -z "$APP_PATH" ]; then
            echo "Built .app not found"
            find build/dd -type d -name '*.app' || true
            exit 1
          fi
          echo "Packaging $APP_PATH"

          rm -rf build/Payload build/${SCHEME}-unsigned.ipa
          mkdir -p build/Payload
          cp -R "$APP_PATH" build/Payload/
          (cd build && zip -qr --symlinks "${SCHEME}-unsigned.ipa" Payload)

          test -f "build/${SCHEME}-unsigned.ipa"
          unzip -l "build/${SCHEME}-unsigned.ipa" | grep -E "Payload/[^/]+\.app/Info.plist"
          unzip -l "build/${SCHEME}-unsigned.ipa" | grep -E "Payload/[^/]+\.app/${SCHEME}$"

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: Smena-ipa-unsigned
          path: build/Smena-unsigned.ipa
          if-no-files-found: error
```

4. Нажми **Commit changes** (в ветку `main`). Сборка запустится автоматически.
5. Вкладка **Actions** → последний запуск → внизу **Artifacts** → скачай `Smena-ipa-unsigned`.
6. Это **zip-архив**. Распакуй его — внутри лежит настоящий `Smena-unsigned.ipa`.
7. Установи `.ipa` через **Esign** (sideload).

### Технологии
SwiftUI · Swift Charts · XcodeGen · iOS 16+ · локальное хранение (Codable + JSON).

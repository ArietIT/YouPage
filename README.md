# YouPage

YouPage — неофициальный Android-клиент EduPage на Flutter, основанный на [EduPage2](https://github.com/DislikesSchool/EduPage2). Проект распространяется по GPL-3.0; файл [LICENSE](LICENSE) сохранён без изменений.

## Возможности

- интерфейс Liquid Glass с полупрозрачными карточками, мягкими тенями, скруглениями и Material You;
- светлая и тёмная темы, включая комфортную для AMOLED тёмную палитру;
- расписание, сообщения, домашние задания, столовая и оценки EduPage2;
- приватный режим оценок включён по умолчанию: нажатие или долгое нажатие показывает оценку на три секунды, доступны размытие и точки;
- скрытые оценки исключены из семантики экранного диктора.

## Важно о входе и приватности

YouPage использует сервер EduPage2 (`ep2.vypal.me`) для входа и кэширования данных. Учётные данные EduPage передаются только этому серверу — это прямо указано на экране входа. Firebase, OneSignal, Shorebird, Sentry и другие аналитические сервисы не используются.

Проект неофициальный и не связан с EduPage или asc Applied Software Consultants, s.r.o. Используйте его на свой риск и в соответствии с правилами EduPage.

## Установка

Откройте **Releases** репозитория, скачайте `app-release.apk` и разрешите установку из этого источника в Android. Целевая платформа — Android 14+, включая Android 15.

## Сборка

Нужны Flutter stable, Android SDK и Java 17:

```sh
flutter pub get
flutter analyze
flutter build apk --release
```

Без `android/key.properties` release APK подписывается отладочным ключом и подходит для тестирования. Для своей подписи GitHub Actions задайте `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`; первый secret — JKS в base64.

`.github/workflows/build.yml` запускается на push в `main`/`master` и вручную, создавая `build-N` с `app-release.apk` и `youpage-source.zip`.

## Структура

- `lib/components/` — компоненты Liquid Glass и маскирование оценок;
- `lib/core/` — локальная конфигурация и настройки приватности;
- `lib/screens/` — вход и настройка;
- `lib/grades.dart`, `lib/timetable.dart`, `lib/messages.dart` — функциональность EduPage2;
- `.github/workflows/build.yml` — CI-сборка.

## Авторы и лицензия

YouPage — производная работа EduPage2. Указано авторство участников исходного проекта: [vyPal](https://github.com/vyPal), WattMann, czmatejt9, SAMUELLL41, Ondass и других. Исходный EduPage2 доступен в [репозитории авторов](https://github.com/DislikesSchool/EduPage2).

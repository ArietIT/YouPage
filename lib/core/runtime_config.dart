/// Локальная конфигурация, которая не требует Firebase или удалённых ключей.
///
/// Адрес можно изменить в настройках приложения. Значение по умолчанию —
/// публичный сервер EduPage2, через который выполняется вход.
class RuntimeConfig {
  RuntimeConfig._();

  static const String defaultBackendUrl = 'https://ep2.vypal.me';
}

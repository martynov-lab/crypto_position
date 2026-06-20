/// Фасад над типизированным key-value хранилищем с дефолтами и удобным [set]
/// значения.
///
/// Реализации для Flutter, Jaspr/web и т.д. живут в соответствующих пакетах,
/// создаются на уровне приложения и передаются через DI.
abstract class SharedPreferencesHelper {
  /// Возвращает [bool] по [key] или [defaultValue], если ключа нет или тип
  /// не совпадает.
  Future<bool> getBool(String key, bool defaultValue);

  /// Возвращает [int] по [key] или [defaultValue], если ключа нет или тип
  /// не совпадает.
  Future<int> getInt(String key, int defaultValue);

  /// Возвращает [double] по [key] или [defaultValue], если ключа нет или
  /// тип не совпадает.
  Future<double> getDouble(String key, double defaultValue);

  /// Возвращает строку по [key] или [defaultValue], если ключа нет или тип
  /// не совпадает.
  Future<String> getString(String key, String defaultValue);

  /// Возвращает список строк по [key] или [defaultValue], если ключа нет
  /// или тип не совпадает.
  Future<List<String>> getStringList(String key, List<String> defaultValue);

  /// Сохраняет [value] в постоянное хранилище.
  ///
  /// Поддерживаются [bool], [int], [double], [String], [List<String>].
  /// Иное значение приводит к ошибке — см. реализацию.
  Future<void> set(String key, Object value);

  /// Удаляет значение по [key].
  Future<bool> remove(String key);

  /// Ключи всех сохранённых значений.
  Future<Iterable<String>> allKeys();

  /// `true`, если для [key] есть сохранённое значение.
  Future<bool> containsKey(String key);
}

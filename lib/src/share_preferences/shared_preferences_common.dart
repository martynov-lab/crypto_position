/// Асинхронное key-value хранилище с типизированными примитивами и списками
/// строк.
///
/// Объединяет сценарии Flutter-плагина shared_preferences и других платформ
/// (например веб через localStorage). Семантика персистентности,
/// атомарности и лимитов зависит от конкретной реализации
/// [SharedPreferencesCommon].
abstract interface class SharedPreferencesCommon {
  /// Возвращает [bool] по [key] или `null`, если ключа нет или тип не совпадает.
  Future<bool?> getBool(String key);

  /// Возвращает [int] по [key] или `null`, если ключа нет или тип не совпадает.
  Future<int?> getInt(String key);

  /// Возвращает [double] по [key] или `null`, если ключа нет или тип не
  /// совпадает.
  Future<double?> getDouble(String key);

  /// Возвращает строку по [key] или `null`, если ключа нет или тип не совпадает.
  Future<String?> getString(String key);

  /// Возвращает список строк по [key] или `null`, если ключа нет или тип не
  /// совпадает.
  Future<List<String>?> getStringList(String key);

  /// Сохраняет [value] по [key]. Возвращаемое значение зависит от реализации
  /// (успех операции).
  Future<bool> setBool(String key, bool value);

  /// Сохраняет [value] по [key]. Возвращаемое значение зависит от реализации
  /// (успех операции).
  Future<bool> setInt(String key, int value);

  /// Сохраняет [value] по [key]. Возвращаемое значение зависит от реализации
  /// (успех операции).
  Future<bool> setDouble(String key, double value);

  /// Сохраняет [value] по [key]. Возвращаемое значение зависит от реализации
  /// (успех операции).
  Future<bool> setString(String key, String value);

  /// Сохраняет [value] по [key]. Возвращаемое значение зависит от реализации
  /// (успех операции).
  Future<bool> setStringList(String key, List<String> value);

  /// Удаляет значение по [key]. Возвращает `true`, если запись была удалена.
  Future<bool> remove(String key);

  /// Итератор ключей, для которых есть сохранённые значения.
  Future<Iterable<String>> allKeys();

  /// `true`, если для [key] есть сохранённое значение.
  Future<bool> containsKey(String key);
}

import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:elementary/elementary.dart';

const keyDeposit = 'DEPOSIT';

class PositionCalculatorModel extends ElementaryModel {
  final SharedPreferencesHelper sharedPreferencesHelper;
  PositionCalculatorModel(this.sharedPreferencesHelper);

  void setValue(String value) {
    sharedPreferencesHelper.set(keyDeposit, value);
  }

  Future<String> getValue() async {
    return await sharedPreferencesHelper.getString(keyDeposit, '0');
  }
}

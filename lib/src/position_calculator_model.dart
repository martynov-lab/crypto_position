import 'package:crypto_position/src/share_preferences/shared_preferences_helper.dart';
import 'package:elementary/elementary.dart';

const keyDeposit = 'DEPOSIT';
const keyRisk = 'RISK';

class PositionCalculatorModel extends ElementaryModel {
  final SharedPreferencesHelper sharedPreferencesHelper;
  PositionCalculatorModel(this.sharedPreferencesHelper);

  void setDepositValue(String value) {
    sharedPreferencesHelper.set(keyDeposit, value);
  }

  Future<String> getDepositValue() async {
    return await sharedPreferencesHelper.getString(keyDeposit, '0');
  }

  void setRiskValue(String value) {
    sharedPreferencesHelper.set(keyRisk, value);
  }

  Future<String> getRiskValue() async {
    return await sharedPreferencesHelper.getString(keyRisk, '1');
  }
}

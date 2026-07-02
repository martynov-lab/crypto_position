import 'package:bybit_account_shared/bybit_account_shared.dart';
import 'package:test/test.dart';

void main() {
  group('WalletBalanceMapper', () {
    test('converts DTO to Model with parsed amounts', () {
      const dto = WalletBalanceDto(
        accountType: 'UNIFIED',
        totalEquity: '123.45',
        totalWalletBalance: '100.5',
        coins: [
          CoinBalanceDto(
            coin: 'BTC',
            equity: '0.5',
            walletBalance: '0.4',
            usdValue: '20000.1',
          ),
        ],
      );

      final model = dto.toModel();

      expect(model.accountType, 'UNIFIED');
      expect(model.totalEquity, 123.45);
      expect(model.totalWalletBalance, 100.5);
      expect(model.coins, hasLength(1));
      expect(model.coins.first.coin, 'BTC');
      expect(model.coins.first.equity, 0.5);
      expect(model.coins.first.usdValue, 20000.1);
    });

    test('parses empty strings as zero (Bybit returns "" for some fields)',
        () {
      const dto = WalletBalanceDto(
        accountType: 'UNIFIED',
        totalEquity: '',
        totalWalletBalance: '',
        coins: [],
      );

      final model = dto.toModel();

      expect(model.totalEquity, 0);
      expect(model.totalWalletBalance, 0);
    });

    test('fromJson maps the "coin" JSON key to coins', () {
      final dto = WalletBalanceDto.fromJson({
        'accountType': 'UNIFIED',
        'totalEquity': '1',
        'totalWalletBalance': '2',
        'coin': [
          {
            'coin': 'ETH',
            'equity': '3',
            'walletBalance': '4',
            'usdValue': '5',
          },
        ],
      });

      expect(dto.coins.single.coin, 'ETH');
    });
  });
}

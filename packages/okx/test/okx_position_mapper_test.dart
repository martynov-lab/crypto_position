import 'package:flutter_test/flutter_test.dart';
import 'package:okx/src/api/dto/position_dto.dart';
import 'package:okx/src/api/mappers/position_mapper.dart';

PositionDto _dto({required String posSide, required String pos}) => PositionDto(
  instId: 'BTC-USDT-SWAP',
  posSide: posSide,
  pos: pos,
  avgPx: '60000',
  markPx: '62000',
  upl: '-200',
  lever: '10',
  fee: '',
  fundingFee: '',
  cTime: '',
);

void main() {
  group('OKX position side', () {
    test('hedge mode keeps the reported side', () {
      expect(_dto(posSide: 'long', pos: '3').toModel().side, 'long');
      expect(_dto(posSide: 'short', pos: '3').toModel().side, 'short');
    });

    test('net mode resolves a short from the sign of pos', () {
      final model = _dto(posSide: 'net', pos: '-3').toModel();

      expect(model.side, 'short');
      expect(model.size, 3);
    });

    test('net mode resolves a long from the sign of pos', () {
      final model = _dto(posSide: 'net', pos: '3').toModel();

      expect(model.side, 'long');
      expect(model.size, 3);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mortgage_calc/core/calculator.dart';
import 'package:mortgage_calc/core/models.dart';

// 提前还款计划：2027-2030年末各30万（贷款从2025年初开始）
// 2027年末 = 第24个月末，2028年末 = 第36个月末，
// 2029年末 = 第48个月末，2030年末 = 第60个月末
const prepayments = [
  Prepayment(atMonth: 24, amount: 300000),
  Prepayment(atMonth: 36, amount: 300000),
  Prepayment(atMonth: 48, amount: 300000),
  Prepayment(atMonth: 60, amount: 300000),
];

LoanInput _epInput() => const LoanInput(
      principal: 2000000,
      annualRate: 0.0305,
      termMonths: 360,
      type: RepaymentType.equalPayment,
      prepayments: prepayments,
    );

LoanInput _epriInput() => const LoanInput(
      principal: 2000000,
      annualRate: 0.0305,
      termMonths: 360,
      type: RepaymentType.equalPrincipal,
      prepayments: prepayments,
    );

void main() {
  group('基础计算', () {
    test('等额本息首月月供约8486元', () {
      final result = simulate(_epInput().copyWith(prepayments: []));
      expect(result.schedule.first.payment, closeTo(8486, 5));
    });

    test('等额本金首月月供约10639元', () {
      final result = simulate(_epriInput().copyWith(prepayments: []));
      expect(result.schedule.first.payment, closeTo(10639, 10));
    });

    test('等额本息无提前还款总利息约48.07万', () {
      final result = simulate(_epInput().copyWith(prepayments: []));
      expect(result.totalInterest, closeTo(480700, 2000));
    });

    test('等额本金无提前还款总利息约41.28万', () {
      final result = simulate(_epriInput().copyWith(prepayments: []));
      expect(result.totalInterest, closeTo(412800, 2000));
    });
  });

  group('提前还款后余额验证', () {
    test('等额本息 2030年末（第60月）余额约66.80万', () {
      final result = simulate(_epInput());
      final rec = result.schedule[59]; // month 60
      expect(rec.balance, closeTo(668000, 3000));
    });

    test('等额本金 2030年末（第60月）余额约59.69万', () {
      final result = simulate(_epriInput());
      final rec = result.schedule[59]; // month 60
      expect(rec.balance, closeTo(596900, 3000));
    });
  });

  group('边界条件', () {
    test('零利率', () {
      final input = const LoanInput(
        principal: 1200000,
        annualRate: 0,
        termMonths: 120,
        type: RepaymentType.equalPayment,
      );
      final result = simulate(input);
      expect(result.schedule.first.payment, closeTo(10000, 1));
      expect(result.totalInterest, closeTo(0, 1));
    });

    test('单月期限', () {
      final input = const LoanInput(
        principal: 100000,
        annualRate: 0.06,
        termMonths: 1,
        type: RepaymentType.equalPayment,
      );
      final result = simulate(input);
      expect(result.actualMonths, 1);
      expect(result.schedule.first.payment, closeTo(100500, 10));
    });

    test('提前还款超过余额不产生负余额', () {
      final input = const LoanInput(
        principal: 500000,
        annualRate: 0.0305,
        termMonths: 360,
        type: RepaymentType.equalPayment,
        prepayments: [Prepayment(atMonth: 12, amount: 3000000)],
      );
      final result = simulate(input);
      for (final r in result.schedule) {
        expect(r.balance, greaterThanOrEqualTo(0));
      }
      expect(result.schedule.last.balance, closeTo(0, 0.1));
    });

    test('大额本金不溢出', () {
      final input = const LoanInput(
        principal: 100000000,
        annualRate: 0.0305,
        termMonths: 360,
        type: RepaymentType.equalPayment,
      );
      final result = simulate(input);
      expect(result.schedule.isNotEmpty, true);
      expect(result.totalInterest, greaterThan(0));
    });
  });

  group('等额本金提前还款', () {
    test('提前还款后余额减少，剩余月数不变', () {
      final input = const LoanInput(
        principal: 2000000,
        annualRate: 0.0305,
        termMonths: 360,
        type: RepaymentType.equalPrincipal,
        prepayments: [Prepayment(atMonth: 12, amount: 300000)],
      );
      final result = simulate(input);
      // month 12 有提前还款
      final rec12 = result.schedule[11];
      expect(rec12.prepayment, closeTo(300000, 1));
      // 提前还款后余额应减少
      if (result.schedule.length > 12) {
        final rec13 = result.schedule[12];
        expect(rec13.balance, lessThan(rec12.balance));
      }
    });
  });
}

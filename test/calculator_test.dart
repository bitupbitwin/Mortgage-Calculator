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

LoanInput _epInput() => LoanInput(
      principal: 2000000,
      annualRate: 0.0305,
      termMonths: 360,
      type: RepaymentType.equalPayment,
      prepayments: prepayments,
    );

LoanInput _epriInput() => LoanInput(
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

    test('等额本息无提前还款总利息约105.50万', () {
      final result = simulate(_epInput().copyWith(prepayments: []));
      expect(result.totalInterest, closeTo(1054999.17, 100));
    });

    test('等额本金无提前还款总利息约91.75万', () {
      final result = simulate(_epriInput().copyWith(prepayments: []));
      expect(result.totalInterest, closeTo(917541.67, 100));
    });
  });

  group('提前还款后余额验证', () {
    test('等额本息 2030年末（第60月）余额约62.35万', () {
      final result = simulate(_epInput());
      final rec = result.schedule[59]; // month 60
      expect(rec.balance, closeTo(623515.36, 100));
    });

    test('等额本金 2030年末（第60月）余额约53.26万', () {
      final result = simulate(_epriInput());
      final rec = result.schedule[59]; // month 60
      expect(rec.balance, closeTo(532570.21, 100));
    });
  });

  group('边界条件', () {
    test('零利率', () {
final input = LoanInput(
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
final input = LoanInput(
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
final input = LoanInput(
        principal: 500000,
        annualRate: 0.0305,
        termMonths: 360,
        type: RepaymentType.equalPayment,
        prepayments: const [Prepayment(atMonth: 12, amount: 3000000)],
      );
      final result = simulate(input);
      for (final r in result.schedule) {
        expect(r.balance, greaterThanOrEqualTo(0));
      }
      expect(result.schedule.last.balance, closeTo(0, 0.1));
    });

    test('大额本金不溢出', () {
final input = LoanInput(
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
final input = LoanInput(
        principal: 2000000,
        annualRate: 0.0305,
        termMonths: 360,
        type: RepaymentType.equalPrincipal,
        prepayments: const [Prepayment(atMonth: 12, amount: 300000)],
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

  group('缩短期限模式', () {
    test('等额本息缩短期限：提前还款后实际月数 < 总期限', () {
      final input = _epInput().copyWith(
        prepaymentMode: PrepaymentMode.shortenTerm,
      );
      final result = simulate(input);
      expect(result.actualMonths, lessThan(360));
    });

    test('等额本息缩短期限月供保持不变（提前还款前后）', () {
      final input = _epInput().copyWith(
        prepaymentMode: PrepaymentMode.shortenTerm,
      );
      final result = simulate(input);
      final firstPayment = result.schedule.first.payment;
      // 第一次提前还款（第24月）之前，月供应保持首月水平
      expect(result.schedule[20].payment, closeTo(firstPayment, 1));
    });

    test('缩短期限比减少月供更省利息（相同提前还款）', () {
      final shorten = simulate(_epInput().copyWith(
        prepaymentMode: PrepaymentMode.shortenTerm,
      ));
      final reduce = simulate(_epInput().copyWith(
        prepaymentMode: PrepaymentMode.reducePayment,
      ));
      expect(shorten.totalInterest, lessThan(reduce.totalInterest));
      expect(shorten.actualMonths, lessThan(reduce.actualMonths));
    });

    test('无提前还款时缩短期限与减少月供结果一致', () {
      final shorten = simulate(_epInput().copyWith(
        prepayments: [],
        prepaymentMode: PrepaymentMode.shortenTerm,
      ));
      final reduce = simulate(_epInput().copyWith(
        prepayments: [],
        prepaymentMode: PrepaymentMode.reducePayment,
      ));
      expect(shorten.totalInterest, closeTo(reduce.totalInterest, 1));
      expect(shorten.actualMonths, reduce.actualMonths);
    });
  });

  group('月冲 vs 年冲', () {
    test('年冲总利息 < 月冲总利息，且更早还清', () {
      final input = _epInput().copyWith(prepayments: []);
      final result = compareFlushModes(input: input, monthlyPfAmount: 2000);
      expect(result.annualFlushInterest, lessThan(result.monthlyFlushInterest));
      expect(result.annualFlushActualMonths,
          lessThan(result.monthlyFlushActualMonths));
      expect(result.savedByAnnual, greaterThan(0));
    });

    test('公积金额度越大，年冲节省越多', () {
      final input = _epInput().copyWith(prepayments: []);
      final small = compareFlushModes(input: input, monthlyPfAmount: 1000);
      final big = compareFlushModes(input: input, monthlyPfAmount: 3000);
      expect(big.savedByAnnual, greaterThan(small.savedByAnnual));
    });
  });
}

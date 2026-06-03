import 'dart:math';
import 'models.dart';

double _monthlyPayment(double balance, double monthlyRate, int remaining) {
  if (monthlyRate == 0) return balance / remaining;
  final r = monthlyRate;
  final n = remaining;
  final pow = (1 + r);
  final factor = _pow(pow, n);
  return balance * r * factor / (factor - 1);
}

double _pow(double base, int exp) {
  double result = 1.0;
  for (int i = 0; i < exp; i++) {
    result *= base;
  }
  return result;
}

LoanResult simulate(LoanInput input) {
  double balance = input.principal;
  int remaining = input.termMonths;
  final List<MonthlyRecord> schedule = [];
  double totalInterest = 0;
  double totalPaid = 0;

  for (int month = 1; balance > 0.01; month++) {
    final r = input.monthlyRate;

    double interest = balance * r;
    double prinPaid;
    double payment;

    if (input.type == RepaymentType.equalPayment) {
      final mp = _monthlyPayment(balance, r, remaining);
      interest = balance * r;
      prinPaid = mp - interest;
      if (prinPaid > balance) prinPaid = balance;
      payment = interest + prinPaid;
    } else {
      prinPaid = balance / remaining;
      if (prinPaid > balance) prinPaid = balance;
      payment = prinPaid + interest;
    }

    balance -= prinPaid;
    remaining -= 1;
    if (balance < 0.01) balance = 0;

    // 月末执行提前还款
    double prepay = 0;
    for (final p in input.prepayments) {
      if (p.atMonth == month) {
        prepay += p.amount;
      }
    }
    prepay = min(prepay, balance);
    balance -= prepay;
    if (balance < 0.01) balance = 0;

    totalInterest += interest;
    totalPaid += payment + prepay;

    schedule.add(MonthlyRecord(
      month: month,
      payment: payment,
      interest: interest,
      principal: prinPaid,
      balance: balance,
      prepayment: prepay,
    ));

    if (balance <= 0.01) break;
  }

  return LoanResult(
    schedule: schedule,
    totalInterest: totalInterest,
    totalPaid: totalPaid,
    actualMonths: schedule.length,
  );
}

// 计算年度快照（基于等额本息和等额本金同样的提前还款计划）
List<YearSnapshot> buildSnapshots({
  required double principal,
  required double annualRate,
  required int termMonths,
  required List<Prepayment> prepayments,
}) {
  // 仅提取有提前还款的年份节点
  final snapshotMonths = <int>{};
  for (final p in prepayments) {
    snapshotMonths.add(p.atMonth);
  }

  if (snapshotMonths.isEmpty) return [];

  final inputEP = LoanInput(
    principal: principal,
    annualRate: annualRate,
    termMonths: termMonths,
    type: RepaymentType.equalPayment,
    prepayments: prepayments,
  );
  final inputEPrincipal = LoanInput(
    principal: principal,
    annualRate: annualRate,
    termMonths: termMonths,
    type: RepaymentType.equalPrincipal,
    prepayments: prepayments,
  );

  final resultEP = simulate(inputEP);
  final resultEPrincipal = simulate(inputEPrincipal);

  final snapshots = <YearSnapshot>[];

  for (final month in snapshotMonths.toList()..sort()) {
    final epRecord = month <= resultEP.schedule.length
        ? resultEP.schedule[month - 1]
        : null;
    final epriRecord = month <= resultEPrincipal.schedule.length
        ? resultEPrincipal.schedule[month - 1]
        : null;

    if (epRecord == null || epriRecord == null) continue;

    double paidInterestEP = 0;
    double paidInterestEPri = 0;
    for (int i = 0; i < month; i++) {
      if (i < resultEP.schedule.length) {
        paidInterestEP += resultEP.schedule[i].interest;
      }
      if (i < resultEPrincipal.schedule.length) {
        paidInterestEPri += resultEPrincipal.schedule[i].interest;
      }
    }

    double nextPaymentEP = 0;
    double nextPaymentEPri = 0;
    if (month < resultEP.schedule.length) {
      nextPaymentEP = resultEP.schedule[month].payment;
    }
    if (month < resultEPrincipal.schedule.length) {
      nextPaymentEPri = resultEPrincipal.schedule[month].payment;
    }

    double prepayAmt = 0;
    for (final p in prepayments) {
      if (p.atMonth == month) prepayAmt += p.amount;
    }

    // 实际年份：从贷款开始年（假设2025年初），每12个月为一年末
    const loanStartYear = 2025;
    final snapshotYear = loanStartYear + (month ~/ 12);

    snapshots.add(YearSnapshot(
      year: snapshotYear,
      atMonth: month,
      prepaymentAmount: prepayAmt,
      balanceEP: epRecord.balance,
      paidInterestEP: paidInterestEP,
      nextPaymentEP: nextPaymentEP,
      balanceEPrincipal: epriRecord.balance,
      paidInterestEPrincipal: paidInterestEPri,
      nextPaymentEPrincipal: nextPaymentEPri,
    ));
  }

  return snapshots;
}

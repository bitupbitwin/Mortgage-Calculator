import 'dart:math';
import 'models.dart';
import 'house_models.dart';

double _monthlyPayment(double balance, double monthlyRate, int remaining) {
  if (monthlyRate == 0) return balance / remaining;
  final factor = pow(1 + monthlyRate, remaining).toDouble();
  return balance * monthlyRate * factor / (factor - 1);
}

LoanResult simulate(LoanInput input) {
  double balance = input.principal;
  int remaining = input.termMonths;
  final List<MonthlyRecord> schedule = [];
  double totalInterest = 0;
  double totalPaid = 0;

  final bool shortenTerm = input.prepaymentMode == PrepaymentMode.shortenTerm;
  final double fixedPayment =
      shortenTerm && input.type == RepaymentType.equalPayment
          ? _monthlyPayment(input.principal, input.monthlyRate, input.termMonths)
          : 0;
  final double fixedPrincipal =
      shortenTerm && input.type == RepaymentType.equalPrincipal
          ? input.principal / input.termMonths
          : 0;

  for (int month = 1; balance > 0.01; month++) {
    final r = input.monthlyRate;
    final double interest = balance * r;
    double prinPaid;
    double payment;

    if (input.type == RepaymentType.equalPayment) {
      final mp =
          shortenTerm ? fixedPayment : _monthlyPayment(balance, r, remaining);
      prinPaid = mp - interest;
      if (prinPaid > balance) prinPaid = balance;
      if (prinPaid < 0) prinPaid = 0;
      payment = interest + prinPaid;
    } else {
      prinPaid = shortenTerm ? fixedPrincipal : balance / remaining;
      if (prinPaid > balance) prinPaid = balance;
      payment = prinPaid + interest;
    }

    balance -= prinPaid;
    remaining -= 1;
    if (balance < 0.01) balance = 0;

    double prepay = 0;
    for (final p in input.prepayments) {
      if (p.atMonth == month) prepay += p.amount;
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

FlushComparisonResult compareFlushModes({
  required LoanInput input,
  required double monthlyPfAmount,
}) {
  // 月冲：按用户选定还款方式正常摊销，无额外提前还款
  final monthlyFlushInput = LoanInput(
    principal: input.principal,
    annualRate: input.annualRate,
    termMonths: input.termMonths,
    type: input.type,
    prepayments: const [],
  );
  final monthlyResult = simulate(monthlyFlushInput);

  // 年冲：每12个月底将积攒的公积金一次性提前还款，100% 冲抵本金
  final annualAmount = monthlyPfAmount * 12;
  final maxYears = (input.termMonths / 12).ceil();
  final annualPrepayments = List.generate(
    maxYears,
    (i) => Prepayment(atMonth: (i + 1) * 12, amount: annualAmount),
  );
  final annualFlushInput = LoanInput(
    principal: input.principal,
    annualRate: input.annualRate,
    termMonths: input.termMonths,
    type: input.type,
    prepayments: annualPrepayments,
    prepaymentMode: PrepaymentMode.shortenTerm,
  );
  final annualResult = simulate(annualFlushInput);

  return FlushComparisonResult(
    monthlyFlushInterest: monthlyResult.totalInterest,
    annualFlushInterest: annualResult.totalInterest,
    monthlyFlushActualMonths: monthlyResult.actualMonths,
    annualFlushActualMonths: annualResult.actualMonths,
    monthlyPfAmount: monthlyPfAmount,
  );
}

List<YearSnapshot> buildSnapshots({
  required double principal,
  required double annualRate,
  required int termMonths,
  required List<Prepayment> prepayments,
  int? loanStartYear,
  PrepaymentMode prepaymentMode = PrepaymentMode.reducePayment,
}) {
  final startYear = loanStartYear ?? DateTime.now().year;

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
    prepaymentMode: prepaymentMode,
    prepayments: prepayments,
  );
  final inputEPrincipal = LoanInput(
    principal: principal,
    annualRate: annualRate,
    termMonths: termMonths,
    type: RepaymentType.equalPrincipal,
    prepaymentMode: prepaymentMode,
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
      if (i < resultEP.schedule.length) paidInterestEP += resultEP.schedule[i].interest;
      if (i < resultEPrincipal.schedule.length) paidInterestEPri += resultEPrincipal.schedule[i].interest;
    }

    double nextPaymentEP = 0;
    double nextPaymentEPri = 0;
    if (month < resultEP.schedule.length) nextPaymentEP = resultEP.schedule[month].payment;
    if (month < resultEPrincipal.schedule.length) nextPaymentEPri = resultEPrincipal.schedule[month].payment;

    double prepayAmt = 0;
    for (final p in prepayments) {
      if (p.atMonth == month) prepayAmt += p.amount;
    }


    snapshots.add(YearSnapshot(
      year: startYear + (month - 1) ~/ 12,
      atMonth: month,
      prepaymentAmount: prepayAmt,
      originalPrincipal: principal,
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

CombinedLoanResult simulateCombined(HouseInput input) {
  LoanResult? pfResult;
  LoanResult? commercialResult;

  if (input.hasPfLoan) {
    pfResult = simulate(LoanInput(
      principal: input.effectivePfLoan,
      annualRate: input.pfAnnualRate,
      termMonths: input.pfTermMonths,
      type: input.repaymentType,
      prepaymentMode: input.prepaymentMode,
      loanStartYear: input.loanStartYear,
    ));
  }

  if (input.hasCommercialLoan) {
    commercialResult = simulate(LoanInput(
      principal: input.commercialLoanAmount,
      annualRate: input.commercialAnnualRate,
      termMonths: input.commercialTermMonths,
      type: input.repaymentType,
      prepaymentMode: input.prepaymentMode,
      loanStartYear: input.loanStartYear,
    ));
  }

  return CombinedLoanResult(
    pfResult: pfResult,
    commercialResult: commercialResult,
  );
}

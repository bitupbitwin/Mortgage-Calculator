enum RepaymentType { equalPayment, equalPrincipal }

class LoanInput {
  final double principal;
  final double annualRate;
  final int termMonths;
  final RepaymentType type;
  final List<Prepayment> prepayments;

  const LoanInput({
    required this.principal,
    required this.annualRate,
    required this.termMonths,
    required this.type,
    this.prepayments = const [],
  });

  double get monthlyRate => annualRate / 12;

  LoanInput copyWith({
    double? principal,
    double? annualRate,
    int? termMonths,
    RepaymentType? type,
    List<Prepayment>? prepayments,
  }) {
    return LoanInput(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      termMonths: termMonths ?? this.termMonths,
      type: type ?? this.type,
      prepayments: prepayments ?? this.prepayments,
    );
  }
}

class Prepayment {
  final int atMonth;
  final double amount;

  const Prepayment({required this.atMonth, required this.amount});
}

class MonthlyRecord {
  final int month;
  final double payment;
  final double interest;
  final double principal;
  final double balance;
  final double prepayment;

  const MonthlyRecord({
    required this.month,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
    required this.prepayment,
  });
}

class LoanResult {
  final List<MonthlyRecord> schedule;
  final double totalInterest;
  final double totalPaid;
  final int actualMonths;

  const LoanResult({
    required this.schedule,
    required this.totalInterest,
    required this.totalPaid,
    required this.actualMonths,
  });
}

class YearSnapshot {
  final int year;
  final int atMonth;
  final double prepaymentAmount;
  final double balanceEP;
  final double paidInterestEP;
  final double nextPaymentEP;
  final double balanceEPrincipal;
  final double paidInterestEPrincipal;
  final double nextPaymentEPrincipal;

  const YearSnapshot({
    required this.year,
    required this.atMonth,
    required this.prepaymentAmount,
    required this.balanceEP,
    required this.paidInterestEP,
    required this.nextPaymentEP,
    required this.balanceEPrincipal,
    required this.paidInterestEPrincipal,
    required this.nextPaymentEPrincipal,
  });
}

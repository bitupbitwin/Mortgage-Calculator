import 'dart:math';
import 'models.dart';

class HouseInput {
  final double housePrice;
  final double downPayment;
  final double agentFeeRate;
  final double deedTaxRate;
  final double pfLoanAmount;
  final double pfAnnualRate;
  final int pfTermMonths;
  final double commercialAnnualRate;
  final int commercialTermMonths;
  final RepaymentType repaymentType;
  final PrepaymentMode prepaymentMode;
  final int loanStartYear;

  HouseInput({
    required this.housePrice,
    required this.downPayment,
    this.agentFeeRate = 0.02,
    this.deedTaxRate = 0.01,
    this.pfLoanAmount = 0,
    this.pfAnnualRate = 0.0305,
    this.pfTermMonths = 360,
    this.commercialAnnualRate = 0.0395,
    this.commercialTermMonths = 360,
    this.repaymentType = RepaymentType.equalPayment,
    this.prepaymentMode = PrepaymentMode.reducePayment,
    int? loanStartYear,
  }) : loanStartYear = loanStartYear ?? DateTime.now().year;

  double get agentFee => housePrice * agentFeeRate;
  double get deedTax => housePrice * deedTaxRate;
  double get extraCost => agentFee + deedTax;
  double get totalCost => housePrice + extraCost;
  double get totalLoan => max(0, totalCost - downPayment);
  double get effectivePfLoan => min(pfLoanAmount, totalLoan);
  double get commercialLoanAmount => max(0, totalLoan - effectivePfLoan);
  double get downPaymentRateOnPrice =>
      housePrice > 0 ? downPayment / housePrice : 0;

  bool get hasPfLoan => effectivePfLoan > 0;
  bool get hasCommercialLoan => commercialLoanAmount > 0;
  bool get hasAnyLoan => totalLoan > 0;

  HouseInput copyWith({
    double? housePrice,
    double? downPayment,
    double? agentFeeRate,
    double? deedTaxRate,
    double? pfLoanAmount,
    double? pfAnnualRate,
    int? pfTermMonths,
    double? commercialAnnualRate,
    int? commercialTermMonths,
    RepaymentType? repaymentType,
    PrepaymentMode? prepaymentMode,
    int? loanStartYear,
  }) {
    return HouseInput(
      housePrice: housePrice ?? this.housePrice,
      downPayment: downPayment ?? this.downPayment,
      agentFeeRate: agentFeeRate ?? this.agentFeeRate,
      deedTaxRate: deedTaxRate ?? this.deedTaxRate,
      pfLoanAmount: pfLoanAmount ?? this.pfLoanAmount,
      pfAnnualRate: pfAnnualRate ?? this.pfAnnualRate,
      pfTermMonths: pfTermMonths ?? this.pfTermMonths,
      commercialAnnualRate: commercialAnnualRate ?? this.commercialAnnualRate,
      commercialTermMonths: commercialTermMonths ?? this.commercialTermMonths,
      repaymentType: repaymentType ?? this.repaymentType,
      prepaymentMode: prepaymentMode ?? this.prepaymentMode,
      loanStartYear: loanStartYear ?? this.loanStartYear,
    );
  }
}

class CombinedLoanResult {
  final LoanResult? pfResult;
  final LoanResult? commercialResult;

  const CombinedLoanResult({this.pfResult, this.commercialResult});

  double get firstMonthPayment {
    double m = 0;
    if (pfResult != null && pfResult!.schedule.isNotEmpty) {
      m += pfResult!.schedule.first.payment;
    }
    if (commercialResult != null && commercialResult!.schedule.isNotEmpty) {
      m += commercialResult!.schedule.first.payment;
    }
    return m;
  }

  double get totalInterest =>
      (pfResult?.totalInterest ?? 0) + (commercialResult?.totalInterest ?? 0);

  double get totalPaid =>
      (pfResult?.totalPaid ?? 0) + (commercialResult?.totalPaid ?? 0);

  int get actualMonths => max(
        pfResult?.actualMonths ?? 0,
        commercialResult?.actualMonths ?? 0,
      );
}

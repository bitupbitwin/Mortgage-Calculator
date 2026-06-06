import 'dart:math';
import 'models.dart';

/// 购房场景下的提前还款节点：同一时间点可分别对公积金贷款与商业贷款
/// 提前还款，允许只填其中一个（另一个为 0）。
class HousePrepayment {
  final int atMonth;
  final double pfAmount;
  final double commercialAmount;

  const HousePrepayment({
    required this.atMonth,
    this.pfAmount = 0,
    this.commercialAmount = 0,
  });

  double get total => pfAmount + commercialAmount;
}

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
  final List<HousePrepayment> prepayments;

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
    this.prepayments = const [],
  }) : loanStartYear = loanStartYear ?? DateTime.now().year;

  double get agentFee => housePrice * agentFeeRate;
  double get deedTax => housePrice * deedTaxRate;
  double get extraCost => agentFee + deedTax;

  /// 购房总成本（房价 + 税费），仅用于展示参考。
  double get totalCost => housePrice + extraCost;

  /// 中介费与契税在购房初期一次性缴纳，并入首付，不进入贷款。
  /// 实际首付 = 用户输入首付 + 税费。
  double get effectiveDownPayment => downPayment + extraCost;

  /// 贷款总额仅基于房价：房价 − 用户输入的首付（税费不进贷款）。
  double get totalLoan => max(0, housePrice - downPayment);

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
    List<HousePrepayment>? prepayments,
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
      prepayments: prepayments ?? this.prepayments,
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

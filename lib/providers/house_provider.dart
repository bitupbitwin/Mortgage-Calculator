import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/house_models.dart';
import '../core/models.dart';
import '../core/calculator.dart';

final houseInputProvider =
    StateNotifierProvider<HouseInputNotifier, HouseInput>(
  (ref) => HouseInputNotifier(),
);

class HouseInputNotifier extends StateNotifier<HouseInput> {
  HouseInputNotifier()
      : super(HouseInput(
          housePrice: 4200000,
          downPayment: 2000000,
          pfLoanAmount: 0,
        )) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        housePrice: prefs.getDouble('h_housePrice'),
        downPayment: prefs.getDouble('h_downPayment'),
        agentFeeRate: prefs.getDouble('h_agentFeeRate'),
        deedTaxRate: prefs.getDouble('h_deedTaxRate'),
        pfLoanAmount: prefs.getDouble('h_pfLoanAmount'),
        pfAnnualRate: prefs.getDouble('h_pfAnnualRate'),
        pfTermMonths: prefs.getInt('h_pfTermMonths'),
        commercialAnnualRate: prefs.getDouble('h_commercialRate'),
        commercialTermMonths: prefs.getInt('h_commercialTermMonths'),
        repaymentType: RepaymentType
            .values[prefs.getInt('h_repaymentType') ?? 0],
        prepaymentMode: PrepaymentMode
            .values[prefs.getInt('h_prepaymentMode') ?? 0],
      );
    } catch (_) {}
  }

  Future<void> update({
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
  }) async {
    state = state.copyWith(
      housePrice: housePrice,
      downPayment: downPayment,
      agentFeeRate: agentFeeRate,
      deedTaxRate: deedTaxRate,
      pfLoanAmount: pfLoanAmount,
      pfAnnualRate: pfAnnualRate,
      pfTermMonths: pfTermMonths,
      commercialAnnualRate: commercialAnnualRate,
      commercialTermMonths: commercialTermMonths,
      repaymentType: repaymentType,
      prepaymentMode: prepaymentMode,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (housePrice != null) prefs.setDouble('h_housePrice', housePrice);
      if (downPayment != null) prefs.setDouble('h_downPayment', downPayment);
      if (agentFeeRate != null) prefs.setDouble('h_agentFeeRate', agentFeeRate);
      if (deedTaxRate != null) prefs.setDouble('h_deedTaxRate', deedTaxRate);
      if (pfLoanAmount != null) prefs.setDouble('h_pfLoanAmount', pfLoanAmount);
      if (pfAnnualRate != null) prefs.setDouble('h_pfAnnualRate', pfAnnualRate);
      if (pfTermMonths != null) prefs.setInt('h_pfTermMonths', pfTermMonths);
      if (commercialAnnualRate != null) {
        prefs.setDouble('h_commercialRate', commercialAnnualRate);
      }
      if (commercialTermMonths != null) {
        prefs.setInt('h_commercialTermMonths', commercialTermMonths);
      }
      if (repaymentType != null) {
        prefs.setInt('h_repaymentType', repaymentType.index);
      }
      if (prepaymentMode != null) {
        prefs.setInt('h_prepaymentMode', prepaymentMode.index);
      }
    } catch (_) {}
  }

  void reset() {
    state = HouseInput(
      housePrice: 4200000,
      downPayment: 2000000,
      pfLoanAmount: 0,
    );
  }
}

final combinedResultProvider = Provider<CombinedLoanResult>((ref) {
  final input = ref.watch(houseInputProvider);
  return simulateCombined(input);
});

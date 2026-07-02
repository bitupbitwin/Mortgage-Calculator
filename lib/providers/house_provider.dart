import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/house_models.dart';
import '../core/models.dart';
import '../core/calculator.dart';

final houseInputProvider =
    StateNotifierProvider<HouseInputNotifier, HouseInput>(
  (ref) => HouseInputNotifier(),
);

List<HousePrepayment> _defaultPrepayments() {
  return const [
    HousePrepayment(atMonth: 12, pfAmount: 200000),
    HousePrepayment(atMonth: 24, pfAmount: 200000),
    HousePrepayment(atMonth: 36, pfAmount: 200000),
    HousePrepayment(atMonth: 48, pfAmount: 200000),
  ];
}

class HouseInputNotifier extends StateNotifier<HouseInput> {
  HouseInputNotifier()
      : super(HouseInput(
          housePrice: 4200000,
          downPayment: 2000000,
          pfLoanAmount: 2000000,
          prepayments: _defaultPrepayments(),
        )) {
    loaded = _loadSaved();
  }

  /// 持久化加载完成信号，UI 可据此回填输入框
  late final Future<void> loaded;

  /// 加载完成前用户已做过修改时，放弃应用已保存值，避免异步回调覆盖新输入
  bool _userModified = false;

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userModified) return;

      // enum 索引防越界：非法值时传 null，copyWith 保留默认
      RepaymentType? savedType;
      final typeIdx = prefs.getInt('h_repaymentType');
      if (typeIdx != null &&
          typeIdx >= 0 &&
          typeIdx < RepaymentType.values.length) {
        savedType = RepaymentType.values[typeIdx];
      }
      PrepaymentMode? savedMode;
      final modeIdx = prefs.getInt('h_prepaymentMode');
      if (modeIdx != null &&
          modeIdx >= 0 &&
          modeIdx < PrepaymentMode.values.length) {
        savedMode = PrepaymentMode.values[modeIdx];
      }

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
        repaymentType: savedType,
        prepaymentMode: savedMode,
        prepayments: _decodePrepayments(prefs.getString('h_prepayments')),
      );
    } catch (_) {}
  }

  /// prefs 里没存过返回 null（保留默认节点）；存过空列表则尊重用户的清空操作
  static List<HousePrepayment>? _decodePrepayments(String? json) {
    if (json == null) return null;
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => HousePrepayment(
                atMonth: (e['m'] as num).toInt(),
                pfAmount: (e['pf'] as num?)?.toDouble() ?? 0,
                commercialAmount: (e['cm'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePrepayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.prepayments
          .map((p) =>
              {'m': p.atMonth, 'pf': p.pfAmount, 'cm': p.commercialAmount})
          .toList());
      await prefs.setString('h_prepayments', json);
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
    _userModified = true;
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

  void addPrepayment(HousePrepayment p) {
    _userModified = true;
    final list = [...state.prepayments, p]
      ..sort((a, b) => a.atMonth.compareTo(b.atMonth));
    state = state.copyWith(prepayments: list);
    _savePrepayments();
  }

  void removePrepayment(int index) {
    _userModified = true;
    final list = [...state.prepayments]..removeAt(index);
    state = state.copyWith(prepayments: list);
    _savePrepayments();
  }

  void updatePrepayment(int index, HousePrepayment p) {
    _userModified = true;
    final list = [...state.prepayments]..[index] = p;
    list.sort((a, b) => a.atMonth.compareTo(b.atMonth));
    state = state.copyWith(prepayments: list);
    _savePrepayments();
  }

  void reset() {
    _userModified = true;
    state = HouseInput(
      housePrice: 4200000,
      downPayment: 2000000,
      pfLoanAmount: 2000000,
      prepayments: _defaultPrepayments(),
    );
    _clearSaved();
  }

  /// 重置时同步清除已保存值，否则重启后旧数据会回来
  Future<void> _clearSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'h_housePrice',
        'h_downPayment',
        'h_agentFeeRate',
        'h_deedTaxRate',
        'h_pfLoanAmount',
        'h_pfAnnualRate',
        'h_pfTermMonths',
        'h_commercialRate',
        'h_commercialTermMonths',
        'h_repaymentType',
        'h_prepaymentMode',
        'h_prepayments',
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}

final combinedResultProvider = Provider<CombinedLoanResult>((ref) {
  final input = ref.watch(houseInputProvider);
  return simulateCombined(input);
});

// 月冲 vs 年冲：以商业贷为主体（公积金通常用于冲抵高利率的商业贷），
// 若无商业贷则退化为公积金贷款。
final houseFlushPfProvider = StateProvider<double>((ref) => 2000.0);

final houseFlushComparisonProvider = Provider<FlushComparisonResult>((ref) {
  final input = ref.watch(houseInputProvider);
  final pfAmount = ref.watch(houseFlushPfProvider);
  final LoanInput loan = input.hasCommercialLoan
      ? LoanInput(
          principal: input.commercialLoanAmount,
          annualRate: input.commercialAnnualRate,
          termMonths: input.commercialTermMonths,
          type: input.repaymentType,
        )
      : LoanInput(
          principal: input.effectivePfLoan > 0 ? input.effectivePfLoan : 1,
          annualRate: input.pfAnnualRate,
          termMonths: input.pfTermMonths,
          type: input.repaymentType,
        );
  return compareFlushModes(input: loan, monthlyPfAmount: pfAmount);
});

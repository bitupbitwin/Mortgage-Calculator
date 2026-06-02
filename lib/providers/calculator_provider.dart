import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../core/calculator.dart';

// 默认参数：上海公积金贷款场景
const _defaultPrincipal = 2000000.0;
const _defaultRate = 0.0305;
const _defaultMonths = 360;
const _defaultPrepayments = [
  Prepayment(atMonth: 24, amount: 300000),
  Prepayment(atMonth: 36, amount: 300000),
  Prepayment(atMonth: 48, amount: 300000),
  Prepayment(atMonth: 60, amount: 300000),
];

final loanInputProvider = StateNotifierProvider<LoanInputNotifier, LoanInput>(
  (ref) => LoanInputNotifier(),
);

class LoanInputNotifier extends StateNotifier<LoanInput> {
  LoanInputNotifier()
      : super(const LoanInput(
          principal: _defaultPrincipal,
          annualRate: _defaultRate,
          termMonths: _defaultMonths,
          type: RepaymentType.equalPayment,
          prepayments: _defaultPrepayments,
        )) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final principal = prefs.getDouble('principal') ?? _defaultPrincipal;
      final rate = prefs.getDouble('annualRate') ?? _defaultRate;
      final months = prefs.getInt('termMonths') ?? _defaultMonths;
      final typeIdx = prefs.getInt('repaymentType') ?? 0;
      state = state.copyWith(
        principal: principal,
        annualRate: rate,
        termMonths: months,
        type: RepaymentType.values[typeIdx],
      );
    } catch (_) {}
  }

  Future<void> update({
    double? principal,
    double? annualRate,
    int? termMonths,
    RepaymentType? type,
    List<Prepayment>? prepayments,
  }) async {
    state = state.copyWith(
      principal: principal,
      annualRate: annualRate,
      termMonths: termMonths,
      type: type,
      prepayments: prepayments,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      if (principal != null) await prefs.setDouble('principal', principal);
      if (annualRate != null) await prefs.setDouble('annualRate', annualRate);
      if (termMonths != null) await prefs.setInt('termMonths', termMonths);
      if (type != null) await prefs.setInt('repaymentType', type.index);
    } catch (_) {}
  }

  void addPrepayment(Prepayment p) {
    final list = [...state.prepayments, p];
    list.sort((a, b) => a.atMonth.compareTo(b.atMonth));
    state = state.copyWith(prepayments: list);
  }

  void removePrepayment(int index) {
    final list = [...state.prepayments];
    list.removeAt(index);
    state = state.copyWith(prepayments: list);
  }

  void reset() {
    state = const LoanInput(
      principal: _defaultPrincipal,
      annualRate: _defaultRate,
      termMonths: _defaultMonths,
      type: RepaymentType.equalPayment,
      prepayments: _defaultPrepayments,
    );
  }
}

final loanResultProvider = Provider<LoanResult>((ref) {
  final input = ref.watch(loanInputProvider);
  return simulate(input);
});

final comparisonResultProvider = Provider<LoanResult>((ref) {
  final input = ref.watch(loanInputProvider);
  final other = input.type == RepaymentType.equalPayment
      ? RepaymentType.equalPrincipal
      : RepaymentType.equalPayment;
  return simulate(input.copyWith(type: other));
});

final snapshotsProvider = Provider<List<YearSnapshot>>((ref) {
  final input = ref.watch(loanInputProvider);
  if (input.prepayments.isEmpty) return [];
  return buildSnapshots(
    principal: input.principal,
    annualRate: input.annualRate,
    termMonths: input.termMonths,
    prepayments: input.prepayments,
  );
});

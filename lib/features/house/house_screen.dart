import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../providers/house_provider.dart';
import '../input/input_widgets.dart';
import 'house_result_screen.dart';

class HouseScreen extends ConsumerStatefulWidget {
  const HouseScreen({super.key});

  @override
  ConsumerState<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends ConsumerState<HouseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _housePriceCtrl;
  late TextEditingController _downPaymentCtrl;
  late TextEditingController _agentFeeCtrl;
  late TextEditingController _deedTaxCtrl;
  late TextEditingController _pfLoanCtrl;
  late TextEditingController _pfRateCtrl;
  late TextEditingController _pfTermCtrl;
  late TextEditingController _commercialRateCtrl;
  late TextEditingController _commercialTermCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(houseInputProvider);
    _housePriceCtrl = TextEditingController(
        text: (s.housePrice / 10000).toStringAsFixed(0));
    _downPaymentCtrl = TextEditingController(
        text: (s.downPayment / 10000).toStringAsFixed(0));
    _agentFeeCtrl = TextEditingController(
        text: (s.agentFeeRate * 100).toStringAsFixed(1));
    _deedTaxCtrl = TextEditingController(
        text: (s.deedTaxRate * 100).toStringAsFixed(1));
    _pfLoanCtrl = TextEditingController(
        text: (s.pfLoanAmount / 10000).toStringAsFixed(0));
    _pfRateCtrl = TextEditingController(
        text: (s.pfAnnualRate * 100).toStringAsFixed(4));
    _pfTermCtrl =
        TextEditingController(text: s.pfTermMonths.toString());
    _commercialRateCtrl = TextEditingController(
        text: (s.commercialAnnualRate * 100).toStringAsFixed(4));
    _commercialTermCtrl =
        TextEditingController(text: s.commercialTermMonths.toString());
  }

  @override
  void dispose() {
    for (final c in [
      _housePriceCtrl,
      _downPaymentCtrl,
      _agentFeeCtrl,
      _deedTaxCtrl,
      _pfLoanCtrl,
      _pfRateCtrl,
      _pfTermCtrl,
      _commercialRateCtrl,
      _commercialTermCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncToProvider() {
    final hp = (double.tryParse(_housePriceCtrl.text) ?? 0) * 10000;
    final dp = (double.tryParse(_downPaymentCtrl.text) ?? 0) * 10000;
    final af = (double.tryParse(_agentFeeCtrl.text) ?? 2) / 100;
    final dt = (double.tryParse(_deedTaxCtrl.text) ?? 1) / 100;
    final pf = (double.tryParse(_pfLoanCtrl.text) ?? 0) * 10000;
    final pfRate = (double.tryParse(_pfRateCtrl.text) ?? 3.05) / 100;
    final pfTerm = int.tryParse(_pfTermCtrl.text) ?? 360;
    final cr = (double.tryParse(_commercialRateCtrl.text) ?? 3.95) / 100;
    final ct = int.tryParse(_commercialTermCtrl.text) ?? 360;

    ref.read(houseInputProvider.notifier).update(
          housePrice: hp,
          downPayment: dp,
          agentFeeRate: af,
          deedTaxRate: dt,
          pfLoanAmount: pf,
          pfAnnualRate: pfRate > 0 ? pfRate : null,
          pfTermMonths: pfTerm > 0 ? pfTerm : null,
          commercialAnnualRate: cr > 0 ? cr : null,
          commercialTermMonths: ct > 0 ? ct : null,
        );
    setState(() {});
  }

  void _resetAll() {
    ref.read(houseInputProvider.notifier).reset();
    final s = ref.read(houseInputProvider);
    _housePriceCtrl.text = (s.housePrice / 10000).toStringAsFixed(0);
    _downPaymentCtrl.text = (s.downPayment / 10000).toStringAsFixed(0);
    _agentFeeCtrl.text = (s.agentFeeRate * 100).toStringAsFixed(1);
    _deedTaxCtrl.text = (s.deedTaxRate * 100).toStringAsFixed(1);
    _pfLoanCtrl.text = (s.pfLoanAmount / 10000).toStringAsFixed(0);
    _pfRateCtrl.text = (s.pfAnnualRate * 100).toStringAsFixed(4);
    _pfTermCtrl.text = s.pfTermMonths.toString();
    _commercialRateCtrl.text = (s.commercialAnnualRate * 100).toStringAsFixed(4);
    _commercialTermCtrl.text = s.commercialTermMonths.toString();
    setState(() {});
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _syncToProvider();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const HouseResultScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final input = ref.watch(houseInputProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('购房综合计算', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHouseSection(input),
              const SizedBox(height: 20),
              _buildFundingSection(input),
              const SizedBox(height: 20),
              _buildCombinedLoanSection(input),
              const SizedBox(height: 20),
              _buildRepaymentSection(input),
              const SizedBox(height: 20),
              _buildPreviewCard(input),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('立即计算', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section helpers ────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3A6B))),
      );

  // ── 1. House info ──────────────────────────────────────────────────

  Widget _buildHouseSection(HouseInput input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('房屋信息'),
        LoanParamField(
          label: '房屋总价',
          hint: '如：420',
          controller: _housePriceCtrl,
          suffix: '万元',
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n <= 0) return '请输入有效房价';
            return null;
          },
          onChanged: (_) => _syncToProvider(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LoanParamField(
                label: '中介费率',
                hint: '2.0',
                controller: _agentFeeCtrl,
                suffix: '%',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 20) return '无效';
                  return null;
                },
                onChanged: (_) => _syncToProvider(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoanParamField(
                label: '契税率',
                hint: '1.0',
                controller: _deedTaxCtrl,
                suffix: '%',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 20) return '无效';
                  return null;
                },
                onChanged: (_) => _syncToProvider(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (input.housePrice > 0) _buildCostRow(input),
      ],
    );
  }

  Widget _buildCostRow(HouseInput input) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCD5EE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(label: '中介费', value: formatWan(input.agentFee)),
          _Divider(),
          _MiniStat(label: '契税', value: formatWan(input.deedTax)),
          _Divider(),
          _MiniStat(
              label: '购房总成本',
              value: formatWan(input.totalCost),
              highlight: true),
        ],
      ),
    );
  }

  // ── 2. Down payment & loan amount ─────────────────────────────────

  Widget _buildFundingSection(HouseInput input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('首付与贷款'),
        LoanParamField(
          label: '首付金额',
          hint: '如：200',
          controller: _downPaymentCtrl,
          suffix: '万元',
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n < 0) return '请输入有效首付';
            return null;
          },
          onChanged: (_) => _syncToProvider(),
        ),
        if (input.housePrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '首付成数 ${(input.downPaymentRateOnPrice * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '贷款总额 ${formatWan(input.totalLoan)}',
                  style: const TextStyle(
                    color: Color(0xFFC8941A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── 3. Combined loan config ────────────────────────────────────────

  Widget _buildCombinedLoanSection(HouseInput input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('组合贷款配置'),
        // PF loan block
        _LoanBlock(
          color: const Color(0xFFF0F4FF),
          borderColor: const Color(0xFFCCD5EE),
          header: Row(
            children: [
              const Icon(Icons.account_balance,
                  size: 16, color: Color(0xFF1B3A6B)),
              const SizedBox(width: 6),
              const Text('公积金贷款',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A6B))),
              const Spacer(),
              Text(
                input.hasPfLoan ? formatWan(input.effectivePfLoan) : '未使用',
                style: TextStyle(
                    fontSize: 13,
                    color: input.hasPfLoan
                        ? const Color(0xFF1B3A6B)
                        : Colors.grey,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          children: [
            LoanParamField(
              label: '贷款金额',
              hint: '0 表示不使用公积金',
              controller: _pfLoanCtrl,
              suffix: '万元',
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return '无效金额';
                if (input.totalLoan > 0 && n * 10000 > input.totalLoan + 1) {
                  return '不能超过贷款总额 ${formatWan(input.totalLoan)}';
                }
                return null;
              },
              onChanged: (_) => _syncToProvider(),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: LoanParamField(
                  label: '年利率',
                  hint: '3.0500',
                  controller: _pfRateCtrl,
                  suffix: '%',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (!input.hasPfLoan) return null;
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 30) return '无效';
                    return null;
                  },
                  onChanged: (_) => _syncToProvider(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoanParamField(
                  label: '期限',
                  hint: '360',
                  controller: _pfTermCtrl,
                  suffix: '月',
                  validator: (v) {
                    if (!input.hasPfLoan) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 600) return '无效';
                    return null;
                  },
                  onChanged: (_) => _syncToProvider(),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        // Commercial loan block
        _LoanBlock(
          color: const Color(0xFFF8F8F8),
          borderColor: const Color(0xFFDDDDDD),
          header: Row(
            children: [
              const Icon(Icons.business, size: 16, color: Color(0xFF1B3A6B)),
              const SizedBox(width: 6),
              const Text('商业贷款',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A6B))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: const Text('自动推算',
                    style: TextStyle(fontSize: 11, color: Color(0xFFC8941A))),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('贷款金额',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    '${formatWan(input.commercialLoanAmount)}（= 贷款总额 − 公积金）',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC8941A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: LoanParamField(
                  label: '年利率',
                  hint: '3.9500',
                  controller: _commercialRateCtrl,
                  suffix: '%',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (!input.hasCommercialLoan) return null;
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 30) return '无效';
                    return null;
                  },
                  onChanged: (_) => _syncToProvider(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoanParamField(
                  label: '期限',
                  hint: '360',
                  controller: _commercialTermCtrl,
                  suffix: '月',
                  validator: (v) {
                    if (!input.hasCommercialLoan) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0 || n > 600) return '无效';
                    return null;
                  },
                  onChanged: (_) => _syncToProvider(),
                ),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  // ── 4. Repayment type ──────────────────────────────────────────────

  Widget _buildRepaymentSection(HouseInput input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('还款方式'),
        RepaymentTypeSelector(
          value: input.repaymentType,
          onChanged: (t) =>
              ref.read(houseInputProvider.notifier).update(repaymentType: t),
        ),
        const SizedBox(height: 12),
        PrepaymentModeSelector(
          value: input.prepaymentMode,
          onChanged: (m) =>
              ref.read(houseInputProvider.notifier).update(prepaymentMode: m),
        ),
      ],
    );
  }

  // ── 5. Live preview ────────────────────────────────────────────────

  Widget _buildPreviewCard(HouseInput input) {
    if (!input.hasAnyLoan) return const SizedBox.shrink();
    final result = ref.watch(combinedResultProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('实时预览',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _PreviewItem(
                  label: '合计首月月供',
                  value: formatMonthly(result.firstMonthPayment),
                  large: true,
                ),
              ),
              Expanded(
                child: _PreviewItem(
                  label: '合计总利息',
                  value: formatWan(result.totalInterest),
                ),
              ),
            ]),
            if (input.hasPfLoan && input.hasCommercialLoan) ...[
              const Divider(height: 20),
              Row(children: [
                Expanded(
                  child: _PreviewItem(
                    label: '公积金月供',
                    value: result.pfResult?.schedule.isNotEmpty == true
                        ? formatMonthly(
                            result.pfResult!.schedule.first.payment)
                        : '-',
                  ),
                ),
                Expanded(
                  child: _PreviewItem(
                    label: '商业贷月供',
                    value:
                        result.commercialResult?.schedule.isNotEmpty == true
                            ? formatMonthly(
                                result.commercialResult!.schedule.first.payment)
                            : '-',
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────────

class _LoanBlock extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Widget header;
  final List<Widget> children;

  const _LoanBlock({
    required this.color,
    required this.borderColor,
    required this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: highlight
                    ? const Color(0xFF1B3A6B)
                    : const Color(0xFF333333))),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: const Color(0xFFCCD5EE));
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _PreviewItem(
      {required this.label, required this.value, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: large ? 22 : 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B3A6B))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../core/house_models.dart';
import '../../providers/house_provider.dart';
import '../schedule/schedule_screen.dart';

class HouseResultScreen extends ConsumerWidget {
  const HouseResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(houseInputProvider);
    final result = ref.watch(combinedResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('购房计算结果',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CostCard(input: input),
            const SizedBox(height: 14),
            _MonthlyCard(input: input, result: result),
            const SizedBox(height: 14),
            _InterestCard(input: input, result: result),
            const SizedBox(height: 14),
            _GrandTotalCard(input: input, result: result),
            const SizedBox(height: 20),
            _buildScheduleButtons(context, input, result),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButtons(
      BuildContext context, HouseInput input, CombinedLoanResult result) {
    return Column(
      children: [
        if (input.hasPfLoan && result.pfResult != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ScheduleScreen(
                              resultOverride: result.pfResult,
                              titleOverride: '公积金还款计划',
                            ))),
                icon: const Icon(Icons.table_rows, size: 16),
                label: const Text('公积金还款计划'),
              ),
            ),
          ),
        if (input.hasCommercialLoan && result.commercialResult != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScheduleScreen(
                            resultOverride: result.commercialResult,
                            titleOverride: '商业贷还款计划',
                          ))),
              icon: const Icon(Icons.table_rows, size: 16),
              label: const Text('商业贷还款计划'),
            ),
          ),
      ],
    );
  }
}

// ── Card: 购房费用明细 ─────────────────────────────────────────────────────────

class _CostCard extends StatelessWidget {
  final HouseInput input;
  const _CostCard({required this.input});

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      title: '购房费用明细',
      children: [
        _Row(label: '房屋总价', value: formatWan(input.housePrice)),
        _Row(
          label: '中介费（${(input.agentFeeRate * 100).toStringAsFixed(1)}%）',
          value: formatWan(input.agentFee),
          valueColor: Colors.grey[700],
        ),
        _Row(
          label: '契税（${(input.deedTaxRate * 100).toStringAsFixed(1)}%）',
          value: formatWan(input.deedTax),
          valueColor: Colors.grey[700],
        ),
        const _HDivider(),
        _Row(
          label: '购房总成本',
          value: formatWan(input.totalCost),
          bold: true,
          valueColor: const Color(0xFF1B3A6B),
        ),
        const SizedBox(height: 8),
        _Row(
          label: '首付（首付成数 ${(input.downPaymentRateOnPrice * 100).toStringAsFixed(1)}%）',
          value: formatWan(input.downPayment),
          bold: true,
        ),
        _Row(
          label: '贷款总额',
          value: formatWan(input.totalLoan),
          bold: true,
          valueColor: const Color(0xFFC8941A),
        ),
        if (input.hasPfLoan)
          _Row(
            label: '  ↳ 公积金贷款',
            value: formatWan(input.effectivePfLoan),
            indent: true,
          ),
        if (input.hasCommercialLoan)
          _Row(
            label: '  ↳ 商业贷款',
            value: formatWan(input.commercialLoanAmount),
            indent: true,
          ),
      ],
    );
  }
}

// ── Card: 月供汇总 ─────────────────────────────────────────────────────────────

class _MonthlyCard extends StatelessWidget {
  final HouseInput input;
  final CombinedLoanResult result;
  const _MonthlyCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    final pfPayment = result.pfResult?.schedule.isNotEmpty == true
        ? result.pfResult!.schedule.first.payment
        : null;
    final commPayment = result.commercialResult?.schedule.isNotEmpty == true
        ? result.commercialResult!.schedule.first.payment
        : null;

    return _ResultCard(
      title: '首月月供',
      children: [
        Center(
          child: Text(
            formatMonthly(result.firstMonthPayment),
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3A6B)),
          ),
        ),
        if (input.hasPfLoan && input.hasCommercialLoan) ...[
          const SizedBox(height: 12),
          const _HDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LoanMini(
                  icon: Icons.account_balance,
                  label: '公积金月供',
                  value: pfPayment != null ? formatMonthly(pfPayment) : '-',
                  sub:
                      '${formatWan(input.effectivePfLoan)} · ${input.pfTermMonths}月',
                ),
              ),
              Container(
                  width: 1, height: 48, color: const Color(0xFFEEEEEE)),
              Expanded(
                child: _LoanMini(
                  icon: Icons.business,
                  label: '商业贷月供',
                  value:
                      commPayment != null ? formatMonthly(commPayment) : '-',
                  sub:
                      '${formatWan(input.commercialLoanAmount)} · ${input.commercialTermMonths}月',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Card: 利息分析 ─────────────────────────────────────────────────────────────

class _InterestCard extends StatelessWidget {
  final HouseInput input;
  final CombinedLoanResult result;
  const _InterestCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      title: '利息与还款分析',
      children: [
        if (input.hasPfLoan && result.pfResult != null) ...[
          _Row(
            label: '公积金利息',
            value: formatWan(result.pfResult!.totalInterest),
          ),
          _Row(
            label: '公积金利率',
            value: '${(input.pfAnnualRate * 100).toStringAsFixed(4)}%  ·  ${result.pfResult!.actualMonths} 个月',
            valueColor: Colors.grey[600],
          ),
        ],
        if (input.hasCommercialLoan && result.commercialResult != null) ...[
          _Row(
            label: '商业贷利息',
            value: formatWan(result.commercialResult!.totalInterest),
          ),
          _Row(
            label: '商业贷利率',
            value: '${(input.commercialAnnualRate * 100).toStringAsFixed(4)}%  ·  ${result.commercialResult!.actualMonths} 个月',
            valueColor: Colors.grey[600],
          ),
        ],
        const _HDivider(),
        _Row(
          label: '合计利息',
          value: formatWan(result.totalInterest),
          bold: true,
          valueColor: Colors.orange[700],
        ),
        _Row(
          label: '合计还款（本 + 息）',
          value: formatWan(result.totalPaid),
          bold: true,
        ),
      ],
    );
  }
}

// ── Card: 总支出 ───────────────────────────────────────────────────────────────

class _GrandTotalCard extends StatelessWidget {
  final HouseInput input;
  final CombinedLoanResult result;
  const _GrandTotalCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    // grandTotal = housePrice + extraCost + totalInterest
    // = downPayment + totalPaid (两种等价写法，费用不重复计入)
    final grandTotal = input.housePrice + input.extraCost + result.totalInterest;

    return _ResultCard(
      title: '最终总支出',
      children: [
        _Row(label: '房屋总价', value: formatWan(input.housePrice)),
        _Row(
          label: '附加费（中介费 + 契税）',
          value: formatWan(input.extraCost),
        ),
        _Row(
          label: '贷款利息',
          value: formatWan(result.totalInterest),
          valueColor: Colors.orange[700],
        ),
        const _HDivider(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text('购房全程总支出',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                formatWan(grandTotal),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B)),
              ),
              Text(
                '= 房价 ${formatWan(input.housePrice)} + 费用 ${formatWan(input.extraCost)} + 利息 ${formatWan(result.totalInterest)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared layout widgets ──────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ResultCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool indent;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.indent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: indent ? Colors.grey[500] : Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? const Color(0xFF333333))),
        ],
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider();
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider());
}

class _LoanMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  const _LoanMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B3A6B)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A6B))),
          Text(sub,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/formatters.dart';
import '../../core/house_models.dart';
import '../../core/models.dart';
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
            _GrandTotalCard(input: input, result: result),
            const SizedBox(height: 14),
            _CostCard(input: input),
            const SizedBox(height: 14),
            _MonthlyCard(input: input, result: result),
            const SizedBox(height: 14),
            _InterestCard(input: input, result: result),
            const SizedBox(height: 14),
            _BalanceCurveCard(result: result),
            const SizedBox(height: 14),
            _PieCard(result: result),
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
          label: '首付（首付成数 ${(input.downPaymentRateOnPrice * 100).toStringAsFixed(1)}%）',
          value: formatWan(input.downPayment),
        ),
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
          label: '实际首付（首付 + 税费）',
          value: formatWan(input.effectiveDownPayment),
          bold: true,
          valueColor: const Color(0xFF1B3A6B),
        ),
        const SizedBox(height: 8),
        _Row(
          label: '贷款总额（房价 − 首付）',
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
    // = effectiveDownPayment + totalPaid (两种等价写法，费用不重复计入)
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

// ── 余额变化曲线 ───────────────────────────────────────────────────────────────

class _BalanceCurveCard extends StatelessWidget {
  final CombinedLoanResult result;
  const _BalanceCurveCard({required this.result});

  List<FlSpot> _spots(LoanResult r) {
    final spots = <FlSpot>[];
    for (int i = 0; i < r.schedule.length; i += 6) {
      spots.add(FlSpot(i.toDouble(), r.schedule[i].balance / 10000));
    }
    // 确保终点为 0
    if (spots.isNotEmpty && spots.last.y > 0) {
      spots.add(FlSpot((r.schedule.length - 1).toDouble(), 0));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final pf = result.pfResult;
    final comm = result.commercialResult;
    if (pf == null && comm == null) return const SizedBox.shrink();

    final lines = <LineChartBarData>[];

    if (pf != null && pf.schedule.isNotEmpty) {
      lines.add(LineChartBarData(
        spots: _spots(pf),
        isCurved: true,
        color: const Color(0xFF1B3A6B),
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xFF1B3A6B).withValues(alpha: 0.08),
        ),
      ));
    }

    if (comm != null && comm.schedule.isNotEmpty) {
      lines.add(LineChartBarData(
        spots: _spots(comm),
        isCurved: true,
        color: const Color(0xFFC8941A),
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xFFC8941A).withValues(alpha: 0.08),
        ),
      ));
    }

    final hasBoth = pf != null && comm != null;

    return _ResultCard(
      title: '余额变化曲线（万元）',
      children: [
        if (hasBoth)
          Row(
            children: [
              _ChartLegend(color: const Color(0xFF1B3A6B), label: '公积金'),
              const SizedBox(width: 16),
              _ChartLegend(color: const Color(0xFFC8941A), label: '商业贷'),
            ],
          ),
        if (hasBoth) const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey[200]!, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 60,
                  getTitlesWidget: (v, _) => Text(
                    '${(v / 12).toInt()}年',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: lines,
          )),
        ),
      ],
    );
  }
}

// ── 本息构成饼图 ───────────────────────────────────────────────────────────────

class _PieCard extends StatelessWidget {
  final CombinedLoanResult result;
  const _PieCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pfInterest = result.pfResult?.totalInterest ?? 0;
    final commInterest = result.commercialResult?.totalInterest ?? 0;
    final pfPrincipal =
        result.pfResult?.schedule.fold(0.0, (s, r) => s + r.principal) ?? 0;
    final commPrincipal =
        result.commercialResult?.schedule.fold(0.0, (s, r) => s + r.principal) ?? 0;

    final totalPrincipal = pfPrincipal + commPrincipal;
    final totalInterest = pfInterest + commInterest;
    final total = totalPrincipal + totalInterest;
    if (total == 0) return const SizedBox.shrink();

    final hasBoth = (result.pfResult != null) && (result.commercialResult != null);

    // 单一贷款：2段（本金+利息）；双贷款：3段（公积金利息、商贷利息、总本金）
    final sections = hasBoth
        ? [
            PieChartSectionData(
              value: pfInterest,
              color: const Color(0xFF1B3A6B),
              title: '公积金\n利息',
              radius: 65,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: commInterest,
              color: const Color(0xFFC8941A),
              title: '商贷\n利息',
              radius: 65,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: totalPrincipal,
              color: const Color(0xFF1B7C67),
              title: '本金',
              radius: 65,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ]
        : [
            PieChartSectionData(
              value: totalPrincipal,
              color: const Color(0xFF0C2B24),
              title: '本金\n${formatWan(totalPrincipal)}',
              radius: 65,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: totalInterest,
              color: const Color(0xFF1B7C67),
              title: '利息\n${formatWan(totalInterest)}',
              radius: 65,
              titleStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ];

    return _ResultCard(
      title: '本息构成',
      children: [
        Row(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              )),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasBoth) ...[
                    _PieLegend(
                      color: const Color(0xFF1B3A6B),
                      label: '公积金利息',
                      value: formatWan(pfInterest),
                      pct: '${(pfInterest / total * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _PieLegend(
                      color: const Color(0xFFC8941A),
                      label: '商贷利息',
                      value: formatWan(commInterest),
                      pct: '${(commInterest / total * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _PieLegend(
                      color: const Color(0xFF1B7C67),
                      label: '还款本金',
                      value: formatWan(totalPrincipal),
                      pct: '${(totalPrincipal / total * 100).toStringAsFixed(1)}%',
                    ),
                  ] else ...[
                    _PieLegend(
                      color: const Color(0xFF0C2B24),
                      label: '还款本金',
                      value: formatWan(totalPrincipal),
                      pct: '${(totalPrincipal / total * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    _PieLegend(
                      color: const Color(0xFF1B7C67),
                      label: '支付利息',
                      value: formatWan(totalInterest),
                      pct: '${(totalInterest / total * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 3, color: color,
            margin: const EdgeInsets.only(right: 6)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String pct;
  const _PieLegend(
      {required this.color,
      required this.label,
      required this.value,
      required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            margin: const EdgeInsets.only(right: 8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text('$value  $pct',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

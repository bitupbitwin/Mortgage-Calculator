import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';
import '../../providers/calculator_provider.dart';
import '../schedule/schedule_screen.dart';
import '../prepayment/prepayment_screen.dart';
import 'comparison_card.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(loanInputProvider);
    final result = ref.watch(loanResultProvider);
    final comparison = ref.watch(comparisonResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计算结果', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_rows_outlined),
            tooltip: '还款计划表',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: '年度快照',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrepaymentScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryCard(input: input, result: result),
            const SizedBox(height: 16),
            ComparisonCard(
                epResult: input.type == RepaymentType.equalPayment
                    ? result
                    : comparison,
                eprincipalResult: input.type == RepaymentType.equalPrincipal
                    ? result
                    : comparison),
            const SizedBox(height: 16),
            _BalanceChart(result: result),
            const SizedBox(height: 16),
            _InterestPieChart(result: result),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScheduleScreen())),
                    icon: const Icon(Icons.table_rows),
                    label: const Text('查看还款计划'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrepaymentScreen())),
                    icon: const Icon(Icons.timeline),
                    label: const Text('年度快照'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final LoanInput input;
  final LoanResult result;

  const _SummaryCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    final firstPayment =
        result.schedule.isNotEmpty ? result.schedule[0].payment : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('首月月供',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      formatMonthly(firstPayment),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C2B24)),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C2B24).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    input.type == RepaymentType.equalPayment ? '等额本息' : '等额本金',
                    style: const TextStyle(
                        color: Color(0xFF0C2B24),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: '贷款本金',
                        value: formatWan(input.principal))),
                Expanded(
                    child: _StatItem(
                        label: '总利息',
                        value: formatWan(result.totalInterest),
                        color: const Color(0xFF1B7C67))),
                Expanded(
                    child: _StatItem(
                        label: '还款总额',
                        value: formatWan(result.totalPaid))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: '年利率',
                        value: formatRate(input.annualRate))),
                Expanded(
                    child: _StatItem(
                        label: '还款期限',
                        value: '${input.termMonths ~/ 12}年')),
                Expanded(
                    child: _StatItem(
                        label: '实际月数',
                        value: '${result.actualMonths}月')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF333333))),
      ],
    );
  }
}

class _BalanceChart extends StatelessWidget {
  final LoanResult result;

  const _BalanceChart({required this.result});

  @override
  Widget build(BuildContext context) {
    // Sample every 6 months for performance
    final spots = <FlSpot>[];
    for (int i = 0; i < result.schedule.length; i += 6) {
      spots.add(FlSpot(
          i.toDouble(), result.schedule[i].balance / 10000));
    }
    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('余额变化曲线（万元）',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2B24))),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        (result.schedule.first.balance / 10000 / 5)
                            .clamp(1, double.infinity),
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
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
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF0C2B24),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color:
                            const Color(0xFF0C2B24).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestPieChart extends StatelessWidget {
  final LoanResult result;

  const _InterestPieChart({required this.result});

  @override
  Widget build(BuildContext context) {
    final principal = result.schedule.fold(0.0, (s, r) => s + r.principal);
    final interest = result.totalInterest;
    final total = principal + interest;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本息构成',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2B24))),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: principal,
                          color: const Color(0xFF0C2B24),
                          title: '本金\n${formatWan(principal)}',
                          radius: 70,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: interest,
                          color: const Color(0xFF1B7C67),
                          title: '利息\n${formatWan(interest)}',
                          radius: 70,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(
                          color: const Color(0xFF0C2B24),
                          label: '本金',
                          value: formatWan(principal),
                          pct: '${(principal / total * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 12),
                      _Legend(
                          color: const Color(0xFF1B7C67),
                          label: '利息',
                          value: formatWan(interest),
                          pct: '${(interest / total * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String pct;

  const _Legend(
      {required this.color,
      required this.label,
      required this.value,
      required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12, height: 12, color: color,
            margin: const EdgeInsets.only(right: 8)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            Text(pct,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

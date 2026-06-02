import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';

class ComparisonCard extends StatelessWidget {
  final LoanResult epResult;
  final LoanResult eprincipalResult;

  const ComparisonCard({
    super.key,
    required this.epResult,
    required this.eprincipalResult,
  });

  @override
  Widget build(BuildContext context) {
    final diff = epResult.totalInterest - eprincipalResult.totalInterest;
    final epFirst = epResult.schedule.isNotEmpty ? epResult.schedule[0].payment : 0;
    final epriFirst = eprincipalResult.schedule.isNotEmpty
        ? eprincipalResult.schedule[0].payment
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('两种方式对比',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _Column(
                  title: '等额本息',
                  firstPayment: epFirst,
                  totalInterest: epResult.totalInterest,
                  totalPaid: epResult.totalPaid,
                  months: epResult.actualMonths,
                  highlight: diff < 0,
                )),
                Container(
                    width: 1, height: 120, color: const Color(0xFFEEEEEE)),
                Expanded(
                    child: _Column(
                  title: '等额本金',
                  firstPayment: epriFirst,
                  totalInterest: eprincipalResult.totalInterest,
                  totalPaid: eprincipalResult.totalPaid,
                  months: eprincipalResult.actualMonths,
                  highlight: diff > 0,
                )),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  diff > 0 ? Icons.info_outline : Icons.check_circle_outline,
                  size: 16,
                  color: diff > 0 ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  diff > 0
                      ? '等额本息比等额本金多付利息 ${formatWan(diff)}'
                      : diff < 0
                          ? '等额本金比等额本息多付利息 ${formatWan(-diff)}'
                          : '两种方式总利息相同',
                  style: TextStyle(
                    fontSize: 13,
                    color: diff > 0 ? Colors.orange[800] : Colors.green[800],
                    fontWeight: FontWeight.w600,
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

class _Column extends StatelessWidget {
  final String title;
  final double firstPayment;
  final double totalInterest;
  final double totalPaid;
  final int months;
  final bool highlight;

  const _Column({
    required this.title,
    required this.firstPayment,
    required this.totalInterest,
    required this.totalPaid,
    required this.months,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: highlight
                          ? Colors.green[700]
                          : const Color(0xFF333333))),
              if (highlight) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14, color: Colors.green),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _Row(label: '首月月供', value: formatMonthly(firstPayment)),
          _Row(label: '总利息', value: formatWan(totalInterest)),
          _Row(label: '还款总额', value: formatWan(totalPaid)),
          _Row(label: '实际月数', value: '$months月'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

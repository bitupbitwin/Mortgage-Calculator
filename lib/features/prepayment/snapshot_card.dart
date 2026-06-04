import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';

class SnapshotCard extends StatelessWidget {
  final YearSnapshot snapshot;

  const SnapshotCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final interestDiff = snapshot.paidInterestEP - snapshot.paidInterestEPrincipal;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B3A6B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snapshot.year} 年末',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '第 ${snapshot.atMonth} 个月末 · 提前还款后',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8941A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatWan(snapshot.prepaymentAmount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Body: dual column
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: _HalfPanel(
                  title: '等额本息',
                  balance: snapshot.balanceEP,
                  paidInterest: snapshot.paidInterestEP,
                  nextPayment: snapshot.nextPaymentEP,
                  originalPrincipal: snapshot.originalPrincipal,
                )),
                Container(width: 1, color: const Color(0xFFEEEEEE)),
                Expanded(
                    child: _HalfPanel(
                  title: '等额本金',
                  balance: snapshot.balanceEPrincipal,
                  paidInterest: snapshot.paidInterestEPrincipal,
                  nextPayment: snapshot.nextPaymentEPrincipal,
                  originalPrincipal: snapshot.originalPrincipal,
                  isRight: true,
                )),
              ],
            ),
          ),
          // Footer: interest diff
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E8),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  interestDiff > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 16,
                  color: interestDiff > 0 ? Colors.orange[700] : Colors.green[700],
                ),
                const SizedBox(width: 6),
                Text(
                  interestDiff > 0
                      ? '已付利息差：等额本息多付 ${formatWan(interestDiff)}'
                      : '已付利息差：等额本金多付 ${formatWan(-interestDiff)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: interestDiff > 0
                        ? Colors.orange[800]
                        : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HalfPanel extends StatelessWidget {
  final String title;
  final double balance;
  final double paidInterest;
  final double nextPayment;
  final double originalPrincipal;
  final bool isRight;

  const _HalfPanel({
    required this.title,
    required this.balance,
    required this.paidInterest,
    required this.nextPayment,
    required this.originalPrincipal,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    // repayment progress: 0 = nothing paid, 1 = fully paid off
    final progressValue = originalPrincipal > 0
        ? (1 - balance / originalPrincipal).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A6B))),
          const SizedBox(height: 10),
          _DataRow(label: '剩余本金', value: formatWan(balance)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFFE0E0E0),
              color: const Color(0xFF1B3A6B),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          _DataRow(label: '已付利息', value: formatWan(paidInterest)),
          const SizedBox(height: 6),
          _DataRow(
            label: '次月月供',
            value: formatMonthly(nextPayment),
            valueStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC8941A)),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DataRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

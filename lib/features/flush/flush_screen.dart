import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers/calculator_provider.dart';

class FlushScreen extends ConsumerStatefulWidget {
  const FlushScreen({super.key});

  @override
  ConsumerState<FlushScreen> createState() => _FlushScreenState();
}

class _FlushScreenState extends ConsumerState<FlushScreen> {
  late TextEditingController _pfCtrl;

  @override
  void initState() {
    super.initState();
    final pfAmount = ref.read(pfAmountProvider);
    _pfCtrl = TextEditingController(text: pfAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _pfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(flushComparisonProvider);

    final savedMonths =
        result.monthlyFlushActualMonths - result.annualFlushActualMonths;
    final savedInterest = result.savedByAnnual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('月冲 vs 年冲',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExplanationCard(),
            const SizedBox(height: 16),
            _buildInputCard(),
            const SizedBox(height: 16),
            _buildComparisonCard(result, savedInterest, savedMonths),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFFC8941A), size: 20),
                SizedBox(width: 8),
                Text('为什么年冲更省钱？',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3A6B),
                        fontSize: 15)),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '月冲：每月用公积金支付月供，月供中包含利息，公积金并未全部冲抵本金。\n\n'
              '年冲：每月自己掏腰包还月供，到年底将12个月积攒的公积金一次性提前还款，'
              '这笔钱100%冲抵剩余本金，减少后续利息计算基数。\n\n'
              '结论：年冲的公积金全部减少本金，利息节省更多。',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('参数设置',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text('每月公积金额度',
                      style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _pfCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      suffixText: '元',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final amount = double.tryParse(v);
                      if (amount != null && amount > 0) {
                        ref.read(pfAmountProvider.notifier).state = amount;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '年冲每次还款额：${formatWan(ref.watch(pfAmountProvider) * 12)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
      dynamic result, double savedInterest, int savedMonths) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('对比结果',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            const SizedBox(height: 16),
            _CompareRow(
              label: '总利息',
              leftLabel: '月冲',
              rightLabel: '年冲',
              leftValue: formatWan(result.monthlyFlushInterest),
              rightValue: formatWan(result.annualFlushInterest),
              rightColor: Colors.green[700],
            ),
            const Divider(height: 24),
            _CompareRow(
              label: '还清月数',
              leftLabel: '月冲',
              rightLabel: '年冲',
              leftValue: '${result.monthlyFlushActualMonths} 个月',
              rightValue: '${result.annualFlushActualMonths} 个月',
              rightColor: Colors.green[700],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: savedInterest > 0
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    savedInterest > 0 ? '年冲比月冲节省' : '月冲比年冲节省',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatWan(savedInterest.abs()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: savedInterest > 0
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                  if (savedMonths > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '提前还清 $savedMonths 个月',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String leftLabel;
  final String rightLabel;
  final String leftValue;
  final String rightValue;
  final Color? rightColor;

  const _CompareRow({
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ValueBox(
                  label: leftLabel, value: leftValue, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ValueBox(
                  label: rightLabel,
                  value: rightValue,
                  color: rightColor ?? const Color(0xFF1B3A6B),
                  highlighted: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool highlighted;

  const _ValueBox({
    required this.label,
    required this.value,
    this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF0F9F0) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? const Color(0xFF1B3A6B))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';
import '../../providers/calculator_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  final LoanResult? resultOverride;
  final String? titleOverride;

  const ScheduleScreen({
    super.key,
    this.resultOverride,
    this.titleOverride,
  });

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _showPrepaymentOnly = false;

  @override
  Widget build(BuildContext context) {
    final LoanResult result =
        widget.resultOverride ?? ref.watch(loanResultProvider);
    final input =
        widget.resultOverride == null ? ref.watch(loanInputProvider) : null;

    final records = _showPrepaymentOnly
        ? result.schedule.where((r) => r.prepayment > 0).toList()
        : result.schedule;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titleOverride ?? '还款计划表',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              const Text('仅提前还款',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(
                value: _showPrepaymentOnly,
                onChanged: (v) => setState(() => _showPrepaymentOnly = v),
                activeThumbColor: const Color(0xFF1B7C67),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryBar(
            result: result,
            repaymentLabel: input != null
                ? (input.type == RepaymentType.equalPayment ? '等额本息' : '等额本金')
                : (widget.titleOverride ?? '贷款'),
          ),
          _TableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (ctx, i) => _RecordRow(
                record: records[i],
                isEven: i % 2 == 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final LoanResult result;
  final String repaymentLabel;

  const _SummaryBar({required this.result, required this.repaymentLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C2B24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Item(label: '还款方式', value: repaymentLabel),
          _Item(label: '总利息', value: formatWan(result.totalInterest)),
          _Item(label: '实际月数', value: '${result.actualMonths}月'),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;

  const _Item({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF555555));
    return Container(
      color: const Color(0xFFDCECE6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: const Row(
        children: [
          SizedBox(
              width: 40,
              child: Text('期数', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 8),
          Expanded(child: Text('月供', style: style, textAlign: TextAlign.right)),
          Expanded(child: Text('利息', style: style, textAlign: TextAlign.right)),
          Expanded(child: Text('还本', style: style, textAlign: TextAlign.right)),
          Expanded(child: Text('余额', style: style, textAlign: TextAlign.right)),
          SizedBox(
              width: 56,
              child: Text('提前还', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final MonthlyRecord record;
  final bool isEven;

  const _RecordRow({required this.record, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final hasPrepay = record.prepayment > 0;
    return Container(
      color: hasPrepay
          ? const Color(0xFFE0F2EC)
          : (isEven ? Colors.white : const Color(0xFFF2F7F5)),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${record.month}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _Cell(formatMonthly(record.payment), bold: true)),
          Expanded(
              child: _Cell(formatMonthly(record.interest),
                  color: const Color(0xFF555555))),
          Expanded(child: _Cell(formatMonthly(record.principal))),
          Expanded(
              child: _Cell(formatWan(record.balance),
                  color: const Color(0xFF0C2B24))),
          SizedBox(
            width: 56,
            child: hasPrepay
                ? Text(
                    formatWan(record.prepayment),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B7C67),
                        fontWeight: FontWeight.w600),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;

  const _Cell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? const Color(0xFF333333)),
    );
  }
}

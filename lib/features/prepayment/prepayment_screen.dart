import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calculator_provider.dart';
import '../../core/formatters.dart';
import 'snapshot_card.dart';

class PrepaymentScreen extends ConsumerWidget {
  const PrepaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(snapshotsProvider);
    final input = ref.watch(loanInputProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('年度快照',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: snapshots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timeline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无提前还款计划',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('请在输入页面添加提前还款节点',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回添加'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _HeaderBanner(
                  prepaymentCount: input.prepayments.length,
                  totalPrepayment: input.prepayments
                      .fold(0.0, (s, p) => s + p.amount),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshots.length,
                    itemBuilder: (ctx, i) =>
                        SnapshotCard(snapshot: snapshots[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final int prepaymentCount;
  final double totalPrepayment;

  const _HeaderBanner(
      {required this.prepaymentCount, required this.totalPrepayment});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C2B24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Item(label: '提前还款次数', value: '$prepaymentCount 次'),
          _Item(
              label: '提前还款总额',
              value: formatWan(totalPrepayment)),
          const _Item(label: '本息双线对比', value: '等额本息 vs 等额本金'),
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
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

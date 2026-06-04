import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';
import '../../providers/calculator_provider.dart';
import '../result/result_screen.dart';
import '../schedule/schedule_screen.dart';
import '../prepayment/prepayment_screen.dart';
import '../flush/flush_screen.dart';
import 'input_widgets.dart';

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _principalCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _monthsCtrl;

  @override
  void initState() {
    super.initState();
    final input = ref.read(loanInputProvider);
    _principalCtrl =
        TextEditingController(text: (input.principal / 10000).toStringAsFixed(0));
    _rateCtrl =
        TextEditingController(text: (input.annualRate * 100).toStringAsFixed(4));
    _monthsCtrl = TextEditingController(text: input.termMonths.toString());
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final principal = double.parse(_principalCtrl.text) * 10000;
    final rate = double.parse(_rateCtrl.text) / 100;
    final months = int.parse(_monthsCtrl.text);
    ref.read(loanInputProvider.notifier).update(
          principal: principal,
          annualRate: rate,
          termMonths: months,
        );
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ResultScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('房贷计算器',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置默认值',
            onPressed: () {
              ref.read(loanInputProvider.notifier).reset();
              final input = ref.read(loanInputProvider);
              _principalCtrl.text =
                  (input.principal / 10000).toStringAsFixed(0);
              _rateCtrl.text =
                  (input.annualRate * 100).toStringAsFixed(4);
              _monthsCtrl.text = input.termMonths.toString();
              setState(() {});
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isTablet
            ? _buildTabletLayout()
            : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildInputPanel(),
          ),
        ),
        Container(width: 1, color: const Color(0xFFDDDDDD)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildPreviewPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInputPanel(),
          const SizedBox(height: 16),
          _buildPreviewPanel(),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    final input = ref.watch(loanInputProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('贷款参数',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3A6B))),
        const SizedBox(height: 16),
        LoanParamField(
          label: '贷款金额',
          hint: '如：200',
          controller: _principalCtrl,
          suffix: '万元',
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n <= 0) return '请输入有效金额';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        LoanParamField(
          label: '年利率',
          hint: '如：3.0500',
          controller: _rateCtrl,
          suffix: '%',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n <= 0 || n > 30) return '请输入有效利率（0-30%）';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        LoanParamField(
          label: '还款期限',
          hint: '如：360',
          controller: _monthsCtrl,
          suffix: '个月',
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n <= 0 || n > 600) return '请输入有效期限（1-600月）';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        RepaymentTypeSelector(
          value: input.type,
          onChanged: (t) =>
              ref.read(loanInputProvider.notifier).update(type: t),
        ),
        const SizedBox(height: 14),
        PrepaymentModeSelector(
          value: input.prepaymentMode,
          onChanged: (m) =>
              ref.read(loanInputProvider.notifier).update(prepaymentMode: m),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('提前还款计划',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3A6B))),
            TextButton.icon(
              onPressed: _showAddPrepaymentDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加节点'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...input.prepayments.asMap().entries.map((e) => PrepaymentRow(
              prepayment: e.value,
              index: e.key,
              loanStartYear: input.loanStartYear,
              onDelete: () =>
                  ref.read(loanInputProvider.notifier).removePrepayment(e.key),
            )),
        if (input.prepayments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('暂无提前还款计划，点击上方添加',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('立即计算', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    final input = ref.watch(loanInputProvider);
    final result = ref.watch(loanResultProvider);
    final comparison = ref.watch(comparisonResultProvider);

    final isEP = input.type == RepaymentType.equalPayment;
    final mainLabel = isEP ? '等额本息' : '等额本金';
    final otherLabel = isEP ? '等额本金' : '等额本息';
    final firstPayment = result.schedule.isNotEmpty
        ? result.schedule[0].payment
        : 0.0;
    final otherFirstPayment = comparison.schedule.isNotEmpty
        ? comparison.schedule[0].payment
        : 0.0;
    final diff = result.totalInterest - comparison.totalInterest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('实时预览（$mainLabel）',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3A6B))),
        const SizedBox(height: 16),
        _PreviewItem(label: '首月月供', value: formatMonthly(firstPayment)),
        _PreviewItem(
            label: '总利息', value: formatWan(result.totalInterest)),
        _PreviewItem(
            label: '还款总额', value: formatWan(result.totalPaid)),
        _PreviewItem(
            label: '实际还清', value: '${result.actualMonths} 个月'),
        const SizedBox(height: 16),
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 8),
        Text('── vs $otherLabel ──',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        _PreviewItem(
            label: '首月月供', value: formatMonthly(otherFirstPayment)),
        _PreviewItem(
            label: '总利息', value: formatWan(comparison.totalInterest)),
        _PreviewItem(
            label: '差额',
            value: diff > 0
                ? '+${formatWan(diff)}（${mainLabel}多）'
                : '${formatWan(diff.abs())}（${mainLabel}少）',
            valueColor: diff > 0 ? Colors.red[700] : Colors.green[700]),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScheduleScreen())),
                icon: const Icon(Icons.table_rows, size: 16),
                label: const Text('还款计划'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrepaymentScreen())),
                icon: const Icon(Icons.timeline, size: 16),
                label: const Text('年度快照'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FlushScreen())),
            icon: const Icon(Icons.compare_arrows, size: 16),
            label: const Text('月冲 vs 年冲'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddPrepaymentDialog() async {
    final input = ref.read(loanInputProvider);
    final result = await showDialog<Prepayment>(
      context: context,
      builder: (_) => AddPrepaymentDialog(loanStartYear: input.loanStartYear),
    );
    if (result != null) {
      ref.read(loanInputProvider.notifier).addPrepayment(result);
    }
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PreviewItem(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF1B3A6B))),
        ],
      ),
    );
  }
}

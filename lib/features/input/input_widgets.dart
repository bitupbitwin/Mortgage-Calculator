import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models.dart';
import '../../core/formatters.dart';

class LoanParamField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const LoanParamField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C2B24))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.grey),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class RepaymentTypeSelector extends StatelessWidget {
  final RepaymentType value;
  final ValueChanged<RepaymentType> onChanged;

  const RepaymentTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('还款方式',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C2B24))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: '等额本息',
                selected: value == RepaymentType.equalPayment,
                onTap: () => onChanged(RepaymentType.equalPayment),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleButton(
                label: '等额本金',
                selected: value == RepaymentType.equalPrincipal,
                onTap: () => onChanged(RepaymentType.equalPrincipal),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PrepaymentModeSelector extends StatelessWidget {
  final PrepaymentMode value;
  final ValueChanged<PrepaymentMode> onChanged;

  const PrepaymentModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('提前还款方式',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B3A6B))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: '减少月供',
                selected: value == PrepaymentMode.reducePayment,
                onTap: () => onChanged(PrepaymentMode.reducePayment),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleButton(
                label: '缩短期限',
                selected: value == PrepaymentMode.shortenTerm,
                onTap: () => onChanged(PrepaymentMode.shortenTerm),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0C2B24) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF071B17) : const Color(0xFFDDDDDD),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: const Color(0xFF0C2B24).withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF333333),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class PrepaymentRow extends StatelessWidget {
  final Prepayment prepayment;
  final int index;
  final int loanStartYear;
  final VoidCallback onDelete;

  const PrepaymentRow({
    super.key,
    required this.prepayment,
    required this.index,
    required this.loanStartYear,
    required this.onDelete,
  });

  String _monthLabel(int month) {
    final year = loanStartYear + (month - 1) ~/ 12;
    final m = ((month - 1) % 12) + 1;
    if (m == 12) return '${year}年末';
    return '${year}年第${m}月末';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EDE8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCAD8D3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0C2B24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _monthLabel(prepayment.atMonth),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            formatWan(prepayment.amount),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B7C67)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class AddPrepaymentDialog extends StatefulWidget {
  final int loanStartYear;

  const AddPrepaymentDialog({super.key, required this.loanStartYear});

  @override
  State<AddPrepaymentDialog> createState() => _AddPrepaymentDialogState();
}

class _AddPrepaymentDialogState extends State<AddPrepaymentDialog> {
  late int _selectedYear;
  int _selectedMonth = 12;
  final _amountController = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.loanStartYear + 1;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _atMonth {
    final yearOffset = _selectedYear - widget.loanStartYear;
    return yearOffset * 12 + _selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(30, (i) => widget.loanStartYear + 1 + i);
    return AlertDialog(
      title: const Text('添加提前还款节点',
          style: TextStyle(color: Color(0xFF0C2B24), fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('年份：', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
              const SizedBox(width: 16),
              const Text('月份：', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '金额（万元）',
              suffixText: '万元',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount == null || amount <= 0) return;
            Navigator.pop(
              context,
              Prepayment(atMonth: _atMonth, amount: amount * 10000),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

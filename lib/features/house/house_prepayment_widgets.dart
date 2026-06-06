import 'package:flutter/material.dart';
import '../../core/formatters.dart';
import '../../core/house_models.dart';

/// 时间标签：贷款开始年 + (月-1)/12 计算所在年；12 月显示为「年末」。
String houseMonthLabel(int month, int loanStartYear) {
  final year = loanStartYear + (month - 1) ~/ 12;
  final m = ((month - 1) % 12) + 1;
  if (m == 12) return '${year}年末';
  return '${year}年第${m}月末';
}

class HousePrepaymentRow extends StatelessWidget {
  final HousePrepayment prepayment;
  final int loanStartYear;
  final VoidCallback onDelete;

  const HousePrepaymentRow({
    super.key,
    required this.prepayment,
    required this.loanStartYear,
    required this.onDelete,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  houseMonthLabel(prepayment.atMonth, loanStartYear),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 12,
                  children: [
                    if (prepayment.pfAmount > 0)
                      Text('公积金 ${formatWan(prepayment.pfAmount)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF1B7C67))),
                    if (prepayment.commercialAmount > 0)
                      Text('商业贷 ${formatWan(prepayment.commercialAmount)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFC8941A))),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class AddHousePrepaymentDialog extends StatefulWidget {
  final int loanStartYear;
  final bool hasPfLoan;
  final bool hasCommercialLoan;

  const AddHousePrepaymentDialog({
    super.key,
    required this.loanStartYear,
    required this.hasPfLoan,
    required this.hasCommercialLoan,
  });

  @override
  State<AddHousePrepaymentDialog> createState() =>
      _AddHousePrepaymentDialogState();
}

class _AddHousePrepaymentDialogState extends State<AddHousePrepaymentDialog> {
  late int _selectedYear;
  int _selectedMonth = 12;
  final _pfController = TextEditingController();
  final _commercialController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.loanStartYear + 1;
  }

  @override
  void dispose() {
    _pfController.dispose();
    _commercialController.dispose();
    super.dispose();
  }

  int get _atMonth {
    final yearOffset = _selectedYear - widget.loanStartYear;
    return yearOffset * 12 + _selectedMonth;
  }

  void _confirm() {
    final pf = (double.tryParse(_pfController.text) ?? 0) * 10000;
    final comm = (double.tryParse(_commercialController.text) ?? 0) * 10000;
    if (pf <= 0 && comm <= 0) {
      setState(() => _error = '请至少输入一项提前还款金额');
      return;
    }
    Navigator.pop(
      context,
      HousePrepayment(
        atMonth: _atMonth,
        pfAmount: pf,
        commercialAmount: comm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(30, (i) => widget.loanStartYear + 1 + i);
    return AlertDialog(
      title: const Text('添加提前还款节点',
          style:
              TextStyle(color: Color(0xFF0C2B24), fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('年份：', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: years
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y年')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
                const SizedBox(width: 16),
                const Text('月份：', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1)
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text('$m月')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('提前还款金额（可只填一项）',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            if (widget.hasPfLoan) ...[
              TextFormField(
                controller: _pfController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '公积金提前还款',
                  suffixText: '万元',
                  prefixIcon: Icon(Icons.account_balance, size: 18),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (widget.hasCommercialLoan)
              TextFormField(
                controller: _commercialController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '商业贷提前还款',
                  suffixText: '万元',
                  prefixIcon: Icon(Icons.business, size: 18),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

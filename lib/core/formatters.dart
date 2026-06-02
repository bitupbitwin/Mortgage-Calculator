String formatCurrency(double amount, {bool showWan = false}) {
  if (showWan && amount >= 10000) {
    final wan = amount / 10000;
    return '${wan.toStringAsFixed(2)}万';
  }
  return '¥${_formatNumber(amount.round())}';
}

String formatWan(double amount) {
  final wan = amount / 10000;
  return '${wan.toStringAsFixed(2)}万';
}

String formatMonthly(double amount) {
  return '¥${_formatNumber(amount.round())}';
}

String formatRate(double rate) {
  return '${(rate * 100).toStringAsFixed(4)}%';
}

String _formatNumber(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  final len = s.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

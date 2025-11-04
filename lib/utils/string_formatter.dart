class StringFormatter {
  StringFormatter._();

  static String formatAmount(dynamic amount) {
    try {
      if (amount is String) {
        return double.parse(amount).toStringAsFixed(2);
      } else if (amount is double) {
        return amount.toStringAsFixed(2);
      } else if (amount is int) {
        return amount.toDouble().toStringAsFixed(2);
      }
      return '0.00';
    } catch (e) {
      return '0.00';
    }
  }
}
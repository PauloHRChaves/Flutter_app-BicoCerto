class StringFormatter {
  StringFormatter._();

  static String formatAmount(dynamic amount) {
    try {
      double value;

      if (amount is String) {
        value = double.parse(amount);
      } else if (amount is double) {
        value = amount;
      } else if (amount is int) {
        value = amount.toDouble();
      } else {
        return '0,00';
      }

      final parts = value.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];

      String formatted = '';
      int count = 0;

      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count == 3) {
          formatted = '.$formatted';
          count = 0;
        }
        formatted = intPart[i] + formatted;
        count++;
      }

      return '$formatted,$decPart';
    } catch (e) {
      return '0,00';
    }
  }
}
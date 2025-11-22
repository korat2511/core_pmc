/// Utility class for formatting numbers in Indian numbering system
/// Formats: K (thousands), L (lakhs), Cr (crores)
class NumberFormatter {
  /// Format amount in Indian numbering system (K, L, Cr)
  /// 
  /// Examples:
  /// - 1,000 -> ₹1K
  /// - 10,000 -> ₹10K
  /// - 1,00,000 -> ₹1L
  /// - 10,00,000 -> ₹10L
  /// - 1,00,00,000 -> ₹1Cr
  /// - 10,00,00,000 -> ₹10Cr
  static String formatIndianCurrency(double amount, {bool showDecimals = false}) {
    if (amount == 0) {
      return '₹0';
    }

    final absAmount = amount.abs();
    final isNegative = amount < 0;
    final prefix = isNegative ? '-₹' : '₹';

    // Crores (1,00,00,000)
    if (absAmount >= 10000000) {
      final crores = absAmount / 10000000;
      if (showDecimals && crores % 1 != 0) {
        return '$prefix${crores.toStringAsFixed(2)}Cr';
      }
      return '$prefix${crores.toStringAsFixed(0)}Cr';
    }

    // Lakhs (1,00,000)
    if (absAmount >= 100000) {
      final lakhs = absAmount / 100000;
      if (showDecimals && lakhs % 1 != 0) {
        return '$prefix${lakhs.toStringAsFixed(2)}L';
      }
      return '$prefix${lakhs.toStringAsFixed(0)}L';
    }

    // Thousands (1,000)
    if (absAmount >= 1000) {
      final thousands = absAmount / 1000;
      if (showDecimals && thousands % 1 != 0) {
        return '$prefix${thousands.toStringAsFixed(2)}K';
      }
      return '$prefix${thousands.toStringAsFixed(0)}K';
    }

    // Less than 1000 - show full amount
    if (showDecimals) {
      return '$prefix${absAmount.toStringAsFixed(2)}';
    }
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }

  /// Format amount with full precision (for detailed views)
  /// Uses Indian numbering system with commas (e.g., 1,00,000.00)
  static String formatFullAmount(double amount) {
    if (amount == 0) {
      return '₹0.00';
    }

    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final prefix = isNegative ? '-₹' : '₹';

    // Split into integer and decimal parts
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Format integer part with Indian numbering system (commas every 2 digits from right, except first 3)
    String formattedInteger = '';
    final reversed = integerPart.split('').reversed.join();
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 2 == 0 && i < reversed.length) {
        formattedInteger = ',' + formattedInteger;
      }
      formattedInteger = reversed[i] + formattedInteger;
    }

    return '$prefix$formattedInteger.$decimalPart';
  }
}


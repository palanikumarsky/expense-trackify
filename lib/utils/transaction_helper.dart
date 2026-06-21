class TransactionHelper {
  static String getCurrencySymbol(String code) {
    switch (code) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'INR': return '₹';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'AUD': return '\$';
      case 'CAD': return '\$';
      case 'SGD': return '\$';
      case 'CNY': return '¥';
      default: return code;
    }
  }
}
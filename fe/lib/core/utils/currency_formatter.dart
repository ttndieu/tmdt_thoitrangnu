// lib/core/utils/currency_formatter.dart

import 'package:intl/intl.dart';

/// Extension format currency cho số
extension CurrencyExtension on num {
  /// Format số tiền theo định dạng Việt Nam
  /// VD: 450000 → "450.000đ"
  String toCurrency() {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(this)}đ';
  }
  
  /// Format không có đơn vị
  /// VD: 450000 → "450.000"
  String toFormattedString() {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return formatter.format(this);
  }
}
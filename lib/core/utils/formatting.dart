import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final format = NumberFormat('#,##0.00', 'en_LY');
  return format.format(amount);
}

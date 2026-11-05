import 'package:intl/intl.dart';

typedef NeedLine = ({String emoji, String name, int qty});

/// Neat, scannable need-list text for the WhatsApp chat.
String build_need_list_message({
  required String customer_name,
  required DateTime pickup_date,
  required List<NeedLine> lines,
}) {
  final day = DateFormat('EEE, d MMM').format(pickup_date);
  final total = lines.fold<int>(0, (sum, line) => sum + line.qty);
  final body = lines.map((l) => '${l.emoji} ${l.name} x ${l.qty}').join('\n');
  return 'Hi! Need-list from $customer_name\n'
      'Pickup: $day\n\n'
      '$body\n\n'
      'Total: $total ${total == 1 ? 'item' : 'items'}';
}

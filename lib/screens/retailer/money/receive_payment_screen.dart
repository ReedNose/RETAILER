import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input_parsing.dart';
import '../../../invoices/current_balance.dart';
import '../../../invoices/format_dollars.dart';
import '../../../invoices/round_money.dart';
import '../../../state/retail_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/retailer/customer_option.dart';
import '../../../widgets/shared/number_field.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';

/// Money received from a customer today. Lowers their balance.
class ReceivePaymentScreen extends ConsumerStatefulWidget {
  const ReceivePaymentScreen({super.key, this.initial_customer_id});

  final String? initial_customer_id;

  @override
  ConsumerState<ReceivePaymentScreen> createState() => _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  String? _customer_id;
  final _amount_controller = TextEditingController();
  bool _is_saving = false;

  @override
  void initState() {
    super.initState();
    _customer_id = widget.initial_customer_id;
  }

  @override
  void dispose() {
    _amount_controller.dispose();
    super.dispose();
  }

  /// Zero is allowed by parse_money (free stock), but a zero payment is noise.
  double? _typed_amount() {
    final amount = parse_money(_amount_controller.text);
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  Future<void> _save() async {
    final customer_id = _customer_id;
    final amount = _typed_amount();
    if (customer_id == null || amount == null) return;

    setState(() => _is_saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(retail_store_provider.notifier).receive_payment(
            customer_id: customer_id,
            amount: amount,
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Payment saved'),
      ));
    } catch (error) {
      if (mounted) setState(() => _is_saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final options = customer_options(snapshot);
    final customer_id = _customer_id;
    final typed = _typed_amount();
    final ready = customer_id != null && typed != null && !_is_saving;
    final owed = customer_id == null
        ? 0.0
        : current_balance(
            ledger: snapshot.ledger,
            payments: snapshot.payments,
            customer_id: customer_id,
            now: DateTime.now(),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Receive payment'), backgroundColor: AppColors.background),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchableDropdown<String>(
            label: 'Customer',
            sheet_title: 'Choose customer',
            options: options,
            selected: option_for(options, _customer_id),
            on_changed: (value) => setState(() => _customer_id = value),
          ),
          if (customer_id != null) ...[
            const SizedBox(height: 14),
            _BalanceCard(
              owed: owed,
              after: typed == null ? null : round_money(owed - typed),
            ),
          ],
          const SizedBox(height: 16),
          NumberField(
            label: 'Amount received',
            controller: _amount_controller,
            decimal: true,
            on_changed: () => setState(() {}),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: ready ? _save : null,
            child: _is_saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save payment'),
          ),
        ],
      ),
    );
  }
}

/// What the customer owes now, and what is left once the typed amount is received.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.owed, required this.after});

  final double owed;
  final double? after;

  @override
  Widget build(BuildContext context) {
    final left = after;
    final is_credit = left != null && left < -0.005;
    final after_color = (left != null && left <= 0.005) ? AppColors.fresh : AppColors.priority;
    return AppCard(
      shadow: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Owes now',
                    style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                const SizedBox(height: 2),
                Text(format_dollars(owed),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFeatures: money_features)),
              ],
            ),
          ),
          if (left != null) ...[
            const Icon(Icons.arrow_forward_rounded, color: AppColors.ink_faint),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(is_credit ? 'Credit after' : 'After payment',
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                const SizedBox(height: 2),
                Text(format_dollars(left.abs()),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFeatures: money_features,
                        color: after_color)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

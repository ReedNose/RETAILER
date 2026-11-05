import 'dart:math';

import 'sku_helpers.dart';

/// Builds a batch_id such as ML_4821 that is not already in the ledger.
/// The ledger keeps every batch ever made, so an id is never reused.
String generate_batch_id(String sku, Set<String> used_ids, {Random? random}) {
  final rng = random ?? Random();
  while (true) {
    final candidate = make_batch_id(sku, (1000 + rng.nextInt(9000)).toString());
    if (!used_ids.contains(candidate)) return candidate;
  }
}

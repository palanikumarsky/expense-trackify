import 'package:flutter/foundation.dart';

/// Increment this notifier whenever transactions are created, updated, or deleted.
/// The HomeScreen listens to it and reloads automatically.
final transactionChangeNotifier = ValueNotifier<int>(0);

void notifyTransactionChange() {
  transactionChangeNotifier.value++;
}

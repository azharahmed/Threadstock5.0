import 'package:flutter/foundation.dart';

/// Central singleton notifier for real-time inventory updates across the app.
/// Whenever stock adjustments, counts, sales, or product tracking mutations occur,
/// this notifier fires so that active inventory views and KPI cards refresh immediately.
class InventoryChangeNotifier extends ChangeNotifier {
  InventoryChangeNotifier._();
  static final InventoryChangeNotifier instance = InventoryChangeNotifier._();

  void notifyInventoryChanged() {
    notifyListeners();
  }
}

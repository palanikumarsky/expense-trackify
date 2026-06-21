import 'dart:async';

class SyncEventBus {
  static final SyncEventBus _instance = SyncEventBus._internal();
  factory SyncEventBus() => _instance;
  SyncEventBus._internal();

  final StreamController<void> _syncController = StreamController.broadcast();

  Stream<void> get onSync => _syncController.stream;

  void notifySync() {
    _syncController.add(null);
  }

  void dispose() {
    _syncController.close();
  }
} 
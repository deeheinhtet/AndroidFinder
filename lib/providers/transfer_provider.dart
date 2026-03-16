import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/conflict_resolution.dart';
import '../models/transfer_task.dart';
import '../services/transfer_service.dart';
import 'adb_provider.dart';

class TransferState {
  final List<TransferTask> tasks;
  final int activeCount;

  const TransferState({
    this.tasks = const [],
    this.activeCount = 0,
  });

  TransferState copyWith({
    List<TransferTask>? tasks,
    int? activeCount,
  }) {
    return TransferState(
      tasks: tasks ?? this.tasks,
      activeCount: activeCount ?? this.activeCount,
    );
  }

  int get completedCount =>
      tasks.where((t) => t.status == TransferStatus.completed).length;
  int get failedCount =>
      tasks.where((t) => t.status == TransferStatus.failed).length;
  int get queuedCount =>
      tasks.where((t) => t.status == TransferStatus.queued).length;
  bool get hasActiveTasks => tasks.any((t) =>
      t.status == TransferStatus.inProgress ||
      t.status == TransferStatus.queued);
}

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferService _transferService;
  StreamSubscription<TransferTask>? _subscription;

  TransferNotifier(this._transferService) : super(const TransferState()) {
    _subscription = _transferService.taskUpdates.listen(_onTaskUpdate);
  }

  void _onTaskUpdate(TransferTask task) {
    final tasks = List<TransferTask>.from(state.tasks);
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    final activeCount =
        tasks.where((t) => t.status == TransferStatus.inProgress).length;
    state = state.copyWith(tasks: tasks, activeCount: activeCount);
  }

  void enqueueDownload(
      String serial, String remotePath, String localPath, String fileName) {
    _transferService.enqueuePull(serial, remotePath, localPath, fileName);
  }

  void enqueueUpload(
      String serial, String localPath, String remotePath, String fileName) {
    _transferService.enqueuePush(serial, localPath, remotePath, fileName);
  }

  void cancelTransfer(String id) {
    _transferService.cancel(id);
  }

  void clearCompleted() {
    _transferService.clearCompleted();
    state = state.copyWith(
      tasks: state.tasks
          .where((t) =>
              t.status == TransferStatus.inProgress ||
              t.status == TransferStatus.queued)
          .toList(),
    );
  }

  void setConflictResolver(
      Future<ConflictResolution> Function(
              String fileName, int? sourceBytes, int? destBytes)?
          resolver) {
    _transferService.setConflictResolver(resolver);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _transferService.dispose();
    super.dispose();
  }
}

final transferProvider =
    StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  return TransferNotifier(ref.read(transferServiceProvider));
});

import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/conflict_resolution.dart';
import '../models/transfer_task.dart';
import 'file_service.dart';

class TransferService {
  final FileService _fileService;
  final _uuid = const Uuid();
  final _tasks = <String, TransferTask>{};
  final _controller = StreamController<TransferTask>.broadcast();
  int _activeCount = 0;

  Future<ConflictResolution> Function(
      String fileName, int? sourceBytes, int? destBytes)? _conflictResolver;

  TransferService(this._fileService);

  void setConflictResolver(
      Future<ConflictResolution> Function(
              String fileName, int? sourceBytes, int? destBytes)?
          resolver) {
    _conflictResolver = resolver;
  }

  Stream<TransferTask> get taskUpdates => _controller.stream;
  List<TransferTask> get allTasks => _tasks.values.toList();

  TransferTask enqueuePull(
      String serial, String remotePath, String localPath, String fileName) {
    final task = TransferTask(
      id: _uuid.v4(),
      fileName: fileName,
      sourcePath: remotePath,
      destinationPath: localPath,
      direction: TransferDirection.deviceToLocal,
      status: TransferStatus.queued,
      totalBytes: 0,
    );
    _tasks[task.id] = task;
    _controller.add(task);
    _processQueue(serial);
    return task;
  }

  TransferTask enqueuePush(
      String serial, String localPath, String remotePath, String fileName) {
    final task = TransferTask(
      id: _uuid.v4(),
      fileName: fileName,
      sourcePath: localPath,
      destinationPath: remotePath,
      direction: TransferDirection.localToDevice,
      status: TransferStatus.queued,
      totalBytes: 0,
    );
    _tasks[task.id] = task;
    _controller.add(task);
    _processQueue(serial);
    return task;
  }

  Future<void> _processQueue(String serial) async {
    if (_activeCount >= AdbConstants.maxConcurrentTransfers) return;

    final queued = _tasks.values
        .where((t) => t.status == TransferStatus.queued)
        .toList();

    for (final task in queued) {
      if (_activeCount >= AdbConstants.maxConcurrentTransfers) break;
      _activeCount++;

      // Get source file size before starting
      int sourceSize = 0;
      try {
        if (task.direction == TransferDirection.deviceToLocal) {
          sourceSize =
              await _fileService.getFileSize(serial, task.sourcePath);
        } else {
          sourceSize = await File(task.sourcePath).length();
        }
      } catch (_) {}

      // Check for file conflicts
      if (_conflictResolver != null) {
        bool destExists = false;
        try {
          if (task.direction == TransferDirection.deviceToLocal) {
            destExists =
                await _fileService.fileExistsLocally(task.destinationPath);
          } else {
            destExists = await _fileService.fileExistsOnDevice(
                serial, task.destinationPath);
          }
        } catch (_) {}

        if (destExists) {
          final resolution = await _conflictResolver!(
              task.fileName, sourceSize > 0 ? sourceSize : null, null);
          if (resolution == ConflictResolution.skip) {
            final cancelled =
                task.copyWith(status: TransferStatus.cancelled);
            _tasks[task.id] = cancelled;
            _controller.add(cancelled);
            _activeCount--;
            continue;
          } else if (resolution == ConflictResolution.renameDestination) {
            final dest = task.destinationPath;
            final lastDot = dest.lastIndexOf('.');
            final lastSlash = dest.lastIndexOf('/');
            String newDest;
            if (lastDot > lastSlash && lastDot >= 0) {
              newDest =
                  '${dest.substring(0, lastDot)}_copy${dest.substring(lastDot)}';
            } else {
              newDest = '${dest}_copy';
            }
            final renamedTask = task.copyWith(destinationPath: newDest);
            _tasks[task.id] = renamedTask;
          }
          // overwrite: just proceed normally
        }
      }

      // Use possibly-updated task from _tasks map
      final currentTask = _tasks[task.id]!;

      final updated = currentTask.copyWith(
        status: TransferStatus.inProgress,
        startedAt: DateTime.now(),
        totalBytes: sourceSize,
      );
      _tasks[task.id] = updated;
      _controller.add(updated);

      try {
        void onProgress(int bytesTransferred) {
          final progressed = updated.copyWith(
            transferredBytes: bytesTransferred,
          );
          _tasks[task.id] = progressed;
          _controller.add(progressed);
        }

        if (currentTask.direction == TransferDirection.deviceToLocal) {
          await _fileService.pullFileWithProgress(
            serial,
            currentTask.sourcePath,
            updated.destinationPath,
            onProgress: onProgress,
          );
        } else {
          await _fileService.pushFileWithProgress(
            serial,
            currentTask.sourcePath,
            updated.destinationPath,
            onProgress: onProgress,
          );
        }

        final completed = _tasks[task.id]!.copyWith(
          status: TransferStatus.completed,
          completedAt: DateTime.now(),
          transferredBytes: sourceSize > 0 ? sourceSize : 0,
        );
        _tasks[task.id] = completed;
        _controller.add(completed);
      } catch (e) {
        final failed = _tasks[task.id]!.copyWith(
          status: TransferStatus.failed,
          errorMessage: e.toString(),
          completedAt: DateTime.now(),
        );
        _tasks[task.id] = failed;
        _controller.add(failed);
      } finally {
        _activeCount--;
      }
    }

    if (_tasks.values.any((t) => t.status == TransferStatus.queued)) {
      _processQueue(serial);
    }
  }

  void cancel(String taskId) {
    final task = _tasks[taskId];
    if (task != null && task.status == TransferStatus.queued) {
      final cancelled = task.copyWith(status: TransferStatus.cancelled);
      _tasks[taskId] = cancelled;
      _controller.add(cancelled);
    }
  }

  void clearCompleted() {
    _tasks.removeWhere((_, t) =>
        t.status == TransferStatus.completed ||
        t.status == TransferStatus.cancelled ||
        t.status == TransferStatus.failed);
  }

  void dispose() {
    _controller.close();
  }
}

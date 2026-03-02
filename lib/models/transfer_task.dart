import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_task.freezed.dart';

enum TransferDirection { deviceToLocal, localToDevice }

enum TransferStatus { queued, inProgress, completed, failed, cancelled }

@freezed
class TransferTask with _$TransferTask {
  const factory TransferTask({
    required String id,
    required String fileName,
    required String sourcePath,
    required String destinationPath,
    required TransferDirection direction,
    required TransferStatus status,
    required int totalBytes,
    @Default(0) int transferredBytes,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _TransferTask;
}

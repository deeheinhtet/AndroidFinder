import 'package:flutter/material.dart';
import '../../core/conflict_resolution.dart';

export '../../core/conflict_resolution.dart';

class ConflictResolutionDialog extends StatelessWidget {
  final String fileName;
  final int? sourceBytes;
  final int? destBytes;

  const ConflictResolutionDialog({
    super.key,
    required this.fileName,
    this.sourceBytes,
    this.destBytes,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File Already Exists'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$fileName" already exists at the destination.'),
          const SizedBox(height: 8),
          Text(
            'What would you like to do?',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.skip),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ConflictResolution.renameDestination),
          child: const Text('Keep Both'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(ConflictResolution.overwrite),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }
}

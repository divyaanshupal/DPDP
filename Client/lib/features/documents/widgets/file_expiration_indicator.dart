import 'package:flutter/material.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/services/file_access_service.dart';

class FileExpirationIndicator extends StatelessWidget {
  final LocalDocument document;
  final FileAccessService fileAccessService;

  const FileExpirationIndicator({
    super.key,
    required this.document,
    required this.fileAccessService,
  });

  @override
  Widget build(BuildContext context) {
    final status = fileAccessService.getFileStatus(document);
    final timeRemaining = fileAccessService.getTimeRemaining(document);

    switch (status) {
      case FileAccessStatus.permanent:
        return const SizedBox.shrink(); // Don't show anything for permanent files
      
      case FileAccessStatus.active:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                fileAccessService.formatTimeRemaining(timeRemaining!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      
      case FileAccessStatus.expiringSoon:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                size: 14,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                fileAccessService.formatTimeRemaining(timeRemaining!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      
      case FileAccessStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 14,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Expired',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
    }
  }
}

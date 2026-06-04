import 'package:flutter/material.dart';

/// Simple progress indicator dialog used for blocking operations.
///
/// Displays a spinner with a [title] and optional [message].
/// Not dismissible by the user.
class ProgressDialog extends StatelessWidget {
  const ProgressDialog({
    super.key,
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

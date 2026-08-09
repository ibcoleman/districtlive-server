import 'package:flutter/material.dart';

/// Reusable empty state widget displayed when no data is available.
///
/// Shows a centered icon and message.
class EmptyState extends StatelessWidget {
  /// Message to display
  final String message;

  /// Icon to display above the message
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.event_busy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.fraction,
    this.subtitle,
    this.error,
  });

  final String title;
  final double fraction;
  final String? subtitle;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: fraction > 0 ? fraction : null,
                minHeight: 8,
              ),
            ),
            if (fraction > 0) ...[
              const SizedBox(height: 8),
              Text(
                FormatUtils.formatPercent(fraction),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.end,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

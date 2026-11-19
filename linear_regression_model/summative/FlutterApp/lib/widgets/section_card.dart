import 'package:flutter/material.dart';

import 'package:earnings_predictor/theme/app_theme.dart';

/// A titled card that stacks its children with equal spacing.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.medium),
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(height: AppSpacing.fieldGap),
            ],
          ],
        ),
      ),
    );
  }
}

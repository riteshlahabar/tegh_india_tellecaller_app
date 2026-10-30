import 'package:flutter/material.dart';

import 'custom_app_bar.dart';

/// Placeholder for the tabs that land in later phases. Keeping one widget for
/// all three means the bottom nav can be reviewed now without three stubs
/// drifting apart.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.phase,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String phase;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: title, isBackButtonExist: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 30, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 18),
              Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                phase,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

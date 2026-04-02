import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: .circular(8),
      child: InkWell(
        borderRadius: .circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: enabled
                        ? (textColor ?? Theme.of(context).colorScheme.onSurface)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  child: leading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? (textColor ??
                                  Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7))
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

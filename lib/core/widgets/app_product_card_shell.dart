import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppProductCardShell extends StatelessWidget {
  const AppProductCardShell({
    required this.image,
    required this.title,
    required this.price,
    this.badge,
    this.subtitle,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget image;
  final String title;
  final Widget price;
  final Widget? badge;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: semanticLabel ?? title,
      child: Material(
        color: Colors.transparent,
        elevation: AppElevations.none,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.neutral800
                            : AppColors.neutral100,
                        child: SizedBox.expand(child: ClipRect(child: image)),
                      ),
                    ),
                    if (badge != null)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: badge,
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 136,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxs,
                    AppSpacing.sm,
                    AppSpacing.xxs,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(width: double.infinity, child: price),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

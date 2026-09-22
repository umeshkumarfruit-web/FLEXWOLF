import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppProductCardShell extends StatelessWidget {
  const AppProductCardShell({
    required this.image,
    required this.title,
    required this.price,
    this.badge,
    this.subtitle,
    this.footer,
    this.onTap,
    this.onWishlist,
    this.semanticLabel,
    super.key,
  });

  final Widget image;
  final String title;
  final Widget price;
  final Widget? badge;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onTap;
  final VoidCallback? onWishlist;
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
                child: SizedBox(
                  width: double.infinity,
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
                        Positioned(
                          top: AppSpacing.xs,
                          left: AppSpacing.xs,
                          child: badge!,
                        ),
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: Material(
                          color: Colors.white,
                          elevation: 2,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onWishlist ?? onTap,
                            child: const Padding(
                              padding: EdgeInsets.all(11),
                              child: Icon(
                                Icons.favorite_border,
                                size: 19,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: footer == null ? 136 : 174,
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
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        footer!,
                      ],
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

import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppPrice extends StatelessWidget {
  const AppPrice({
    required this.price,
    this.compareAtPrice,
    this.semanticLabel,
    super.key,
  });

  final String price;
  final String? compareAtPrice;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasSale =
        compareAtPrice != null && _isHigherPrice(compareAtPrice!, price);

    return Semantics(
      label:
          semanticLabel ??
          (hasSale
              ? 'Sale price $price, regular price $compareAtPrice'
              : price),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (hasSale ? AppTypography.salePrice : AppTypography.price)
                  .copyWith(color: hasSale ? AppColors.sale : colors.onSurface),
            ),
            if (hasSale) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                compareAtPrice!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: colors.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _isHigherPrice(String compareAtPrice, String price) {
  num? amount(String value) {
    final matches = RegExp(r'-?\d+(?:\.\d+)?').allMatches(value);
    return matches.isEmpty ? null : num.tryParse(matches.last.group(0) ?? '');
  }

  final current = amount(price);
  final regular = amount(compareAtPrice);
  return current != null && regular != null && regular > current;
}

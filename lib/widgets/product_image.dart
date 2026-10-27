import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/image_resolver.dart';
import '../theme.dart';

/// Thumbnail that lazily loads a product's image. Shows a soft branded
/// placeholder while fetching and falls back to a category icon on error.
class ProductImage extends StatelessWidget {
  final Product? product;
  final String? name, variety;
  final Category? category;
  final double size;
  final double radius;
  const ProductImage({super.key, this.product, this.name, this.variety, this.category, this.size = 56, this.radius = 12})
      : assert(product != null || (name != null && category != null));

  String _url() {
    if (product != null) return ImageResolver.forProduct(product!, size: size.round() * 2);
    return ImageResolver.forName(name: name!, variety: variety ?? '', category: category!, size: size.round() * 2);
  }

  IconData get _fallbackIcon {
    final c = product?.category ?? category ?? Category.flower;
    return switch (c) {
      Category.flower => Icons.local_florist,
      Category.bouquet => Icons.card_giftcard,
      Category.accessory => Icons.shopping_bag_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.primarySoft, Color(0xFFFFFBF7)],
          ),
          border: Border.all(color: AppColors.primaryBorder),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Image.network(
          _url(),
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, prog) {
            if (prog == null) return child;
            return Center(
              child: Icon(_fallbackIcon, color: AppColors.primary.withValues(alpha: 0.5), size: size * 0.42),
            );
          },
          errorBuilder: (ctx, err, st) => Center(
            child: Icon(_fallbackIcon, color: AppColors.primary, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

import '../data/catalog.dart';
import '../data/models.dart';

/// Resolves a product to an image URL. Hot path: lookup in curated catalog by
/// (name, variety); miss → fall back to a seeded picsum.photos URL so even
/// hand-entered products still get a stable thumbnail.
class ImageResolver {
  static final Map<String, CatalogItem> _byKey = {
    for (final c in seedCatalog) _key(c.name, c.variety): c,
  };

  static String _key(String name, String variety) =>
      '${name.trim().toLowerCase()}|${variety.trim().toLowerCase()}';

  static String forProduct(Product p, {int size = 400}) {
    final hit = _byKey[_key(p.name, p.variety)];
    if (hit != null) {
      return imageUrlFor(unsplashId: hit.unsplashId, seed: hit.imageSeed, size: size);
    }
    final seed = '${p.category.name}-${p.name}-${p.variety}'.toLowerCase();
    return imageUrlFor(seed: seed.isEmpty ? 'flora-${p.id}' : seed, size: size);
  }

  static String forName({required String name, required String variety, required Category category, int size = 400}) {
    final hit = _byKey[_key(name, variety)];
    if (hit != null) {
      return imageUrlFor(unsplashId: hit.unsplashId, seed: hit.imageSeed, size: size);
    }
    final seed = '${category.name}-$name-$variety'.toLowerCase();
    return imageUrlFor(seed: seed.isEmpty ? 'flora' : seed, size: size);
  }
}

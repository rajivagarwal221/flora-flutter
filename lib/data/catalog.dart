// Curated seed catalog for Flora Studio: flowers and bouquets.
// Only visually-verified Unsplash photo ids are pinned; everything else falls
// back to a seeded picsum url (stable per product name, no CORS issues on web).

class CatalogItem {
  final String name;
  final String variety;
  final String unit;
  final String category; // 'flower' | 'bouquet' | 'accessory'
  final double purchasePrice;
  final double sellingPrice;
  final double stock;
  final String supplier;
  final String? unsplashId;
  final String imageSeed; // used for the picsum fallback
  const CatalogItem({
    required this.name,
    required this.variety,
    required this.unit,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stock,
    required this.supplier,
    required this.imageSeed,
    this.unsplashId,
  });

  Map<String, dynamic> toInput() => {
    'name': name,
    'variety': variety,
    'unit': unit,
    'category': category,
    'purchase_price': purchasePrice,
    'selling_price': sellingPrice,
    'stock': stock,
    'supplier': supplier,
  };
}

// Verified flower photo ids (checked visually against Unsplash):
const _redRose  = '1562690868-60bbe7293e94';  // dewy red rose
const _pinkRose = '1455582916367-25f75bfc6710'; // pink rose bloom
const _tulips   = '1468327768560-75b778cbb551'; // pink/white tulips
const _yellow1  = '1470509037663-253afd7f0f51'; // sunflower
const _yellow2  = '1490750967868-88aa4486c946'; // yellow garden flowers
const _peony    = '1527061011665-3652c757a4d4'; // pink peony cluster

const List<CatalogItem> seedCatalog = [
  // ---- Flowers ----
  CatalogItem(name: 'Rose', variety: 'Red', unit: 'stem', category: 'flower',
    purchasePrice: 8, sellingPrice: 18, stock: 240, supplier: 'Pune Growers',
    unsplashId: _redRose, imageSeed: 'rose-red'),
  CatalogItem(name: 'Rose', variety: 'White', unit: 'stem', category: 'flower',
    purchasePrice: 9, sellingPrice: 20, stock: 180, supplier: 'Pune Growers',
    unsplashId: _pinkRose, imageSeed: 'rose-white'),
  CatalogItem(name: 'Rose', variety: 'Pink', unit: 'stem', category: 'flower',
    purchasePrice: 8, sellingPrice: 18, stock: 160, supplier: 'Pune Growers',
    unsplashId: _pinkRose, imageSeed: 'rose-pink'),
  CatalogItem(name: 'Rose', variety: 'Yellow', unit: 'stem', category: 'flower',
    purchasePrice: 9, sellingPrice: 20, stock: 90, supplier: 'Pune Growers',
    unsplashId: _yellow1, imageSeed: 'rose-yellow'),
  CatalogItem(name: 'Tulip', variety: 'Dutch', unit: 'stem', category: 'flower',
    purchasePrice: 25, sellingPrice: 55, stock: 60, supplier: 'Blossom Imports',
    unsplashId: _tulips, imageSeed: 'tulip'),
  CatalogItem(name: 'Lily', variety: 'Oriental', unit: 'stem', category: 'flower',
    purchasePrice: 35, sellingPrice: 80, stock: 70, supplier: 'Blossom Imports',
    unsplashId: _pinkRose, imageSeed: 'lily-oriental'),
  CatalogItem(name: 'Lily', variety: 'Asiatic', unit: 'stem', category: 'flower',
    purchasePrice: 28, sellingPrice: 65, stock: 85, supplier: 'Blossom Imports',
    unsplashId: _yellow2, imageSeed: 'lily-asiatic'),
  CatalogItem(name: 'Carnation', variety: 'Red', unit: 'stem', category: 'flower',
    purchasePrice: 6, sellingPrice: 14, stock: 300, supplier: 'Nashik Farms',
    unsplashId: _redRose, imageSeed: 'carnation-red'),
  CatalogItem(name: 'Carnation', variety: 'Pink', unit: 'stem', category: 'flower',
    purchasePrice: 6, sellingPrice: 14, stock: 260, supplier: 'Nashik Farms',
    unsplashId: _pinkRose, imageSeed: 'carnation-pink'),
  CatalogItem(name: 'Gerbera', variety: 'Mixed', unit: 'stem', category: 'flower',
    purchasePrice: 10, sellingPrice: 22, stock: 150, supplier: 'Nashik Farms',
    unsplashId: _peony, imageSeed: 'gerbera'),
  CatalogItem(name: 'Orchid', variety: 'Dendrobium', unit: 'stem', category: 'flower',
    purchasePrice: 45, sellingPrice: 95, stock: 50, supplier: 'Blossom Imports',
    unsplashId: _pinkRose, imageSeed: 'orchid'),
  CatalogItem(name: 'Sunflower', variety: 'Classic', unit: 'stem', category: 'flower',
    purchasePrice: 20, sellingPrice: 45, stock: 70, supplier: 'Pune Growers',
    unsplashId: _yellow1, imageSeed: 'sunflower'),
  CatalogItem(name: 'Chrysanthemum', variety: 'Spray', unit: 'bunch', category: 'flower',
    purchasePrice: 30, sellingPrice: 65, stock: 40, supplier: 'Nashik Farms',
    unsplashId: _yellow2, imageSeed: 'chrysanthemum'),
  CatalogItem(name: 'Daisy', variety: 'Shasta', unit: 'bunch', category: 'flower',
    purchasePrice: 15, sellingPrice: 35, stock: 55, supplier: 'Nashik Farms',
    unsplashId: _pinkRose, imageSeed: 'daisy'),
  CatalogItem(name: 'Baby Breath', variety: 'Gypsophila', unit: 'bunch', category: 'flower',
    purchasePrice: 25, sellingPrice: 55, stock: 90, supplier: 'Pune Growers',
    unsplashId: _pinkRose, imageSeed: 'baby-breath'),
  CatalogItem(name: 'Eucalyptus', variety: 'Silver Dollar', unit: 'bunch', category: 'flower',
    purchasePrice: 20, sellingPrice: 45, stock: 110, supplier: 'Pune Growers',
    unsplashId: _yellow2, imageSeed: 'eucalyptus'),
  CatalogItem(name: 'Hydrangea', variety: 'Blue', unit: 'stem', category: 'flower',
    purchasePrice: 55, sellingPrice: 120, stock: 35, supplier: 'Blossom Imports',
    unsplashId: _tulips, imageSeed: 'hydrangea'),
  CatalogItem(name: 'Peony', variety: 'Coral', unit: 'stem', category: 'flower',
    purchasePrice: 85, sellingPrice: 180, stock: 25, supplier: 'Blossom Imports',
    unsplashId: _peony, imageSeed: 'peony'),
  CatalogItem(name: 'Marigold', variety: 'Orange', unit: 'kg', category: 'flower',
    purchasePrice: 60, sellingPrice: 120, stock: 20, supplier: 'Local Market',
    unsplashId: _yellow2, imageSeed: 'marigold'),
  CatalogItem(name: 'Jasmine', variety: 'Mogra', unit: 'garland', category: 'flower',
    purchasePrice: 40, sellingPrice: 80, stock: 30, supplier: 'Local Market',
    unsplashId: _pinkRose, imageSeed: 'jasmine'),

  // ---- Bouquet-making accessories ----
  CatalogItem(name: 'Floral Foam', variety: 'Oasis Block', unit: 'piece', category: 'accessory',
    purchasePrice: 35, sellingPrice: 80, stock: 60, supplier: 'FlorKraft',
    imageSeed: 'floral-foam'),
  CatalogItem(name: 'Craft Paper', variety: 'Kraft Brown', unit: 'sheet', category: 'accessory',
    purchasePrice: 8, sellingPrice: 20, stock: 400, supplier: 'FlorKraft',
    imageSeed: 'kraft-paper'),
  CatalogItem(name: 'Cellophane', variety: 'Clear Roll', unit: 'sheet', category: 'accessory',
    purchasePrice: 5, sellingPrice: 15, stock: 500, supplier: 'FlorKraft',
    imageSeed: 'cellophane'),
  CatalogItem(name: 'Ribbon', variety: 'Satin Pink', unit: 'piece', category: 'accessory',
    purchasePrice: 15, sellingPrice: 35, stock: 120, supplier: 'FlorKraft',
    imageSeed: 'ribbon-pink'),
  CatalogItem(name: 'Ribbon', variety: 'Satin White', unit: 'piece', category: 'accessory',
    purchasePrice: 15, sellingPrice: 35, stock: 110, supplier: 'FlorKraft',
    imageSeed: 'ribbon-white'),
  CatalogItem(name: 'Floral Tape', variety: 'Green', unit: 'piece', category: 'accessory',
    purchasePrice: 25, sellingPrice: 60, stock: 80, supplier: 'FlorKraft',
    imageSeed: 'floral-tape'),
  CatalogItem(name: 'Floral Wire', variety: '22 Gauge', unit: 'piece', category: 'accessory',
    purchasePrice: 20, sellingPrice: 50, stock: 90, supplier: 'FlorKraft',
    imageSeed: 'floral-wire'),
  CatalogItem(name: 'Scissors', variety: 'Florist Pro', unit: 'piece', category: 'accessory',
    purchasePrice: 180, sellingPrice: 350, stock: 15, supplier: 'FlorKraft',
    imageSeed: 'scissors'),
  CatalogItem(name: 'Glass Vase', variety: 'Cylinder 25cm', unit: 'piece', category: 'accessory',
    purchasePrice: 120, sellingPrice: 280, stock: 40, supplier: 'Vase Studio',
    imageSeed: 'vase-cylinder'),
  CatalogItem(name: 'Glass Vase', variety: 'Bud Mini', unit: 'piece', category: 'accessory',
    purchasePrice: 60, sellingPrice: 150, stock: 55, supplier: 'Vase Studio',
    imageSeed: 'vase-bud'),
  CatalogItem(name: 'Gift Box', variety: 'Rose Hat Box', unit: 'piece', category: 'accessory',
    purchasePrice: 150, sellingPrice: 320, stock: 25, supplier: 'FlorKraft',
    imageSeed: 'hat-box'),
  CatalogItem(name: 'Greeting Card', variety: 'Blank', unit: 'piece', category: 'accessory',
    purchasePrice: 10, sellingPrice: 30, stock: 200, supplier: 'Paper Co',
    imageSeed: 'greeting-card'),

  // ---- Prebuilt bouquets ----
  CatalogItem(name: 'Classic Rose Bouquet', variety: '12 Red Roses', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 650, stock: 0, supplier: '',
    unsplashId: _redRose, imageSeed: 'bouquet-roses'),
  CatalogItem(name: 'Mixed Season Bouquet', variety: 'Seasonal Mix', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 850, stock: 0, supplier: '',
    unsplashId: _peony, imageSeed: 'bouquet-mix'),
  CatalogItem(name: 'Lily Elegance', variety: 'Oriental Lily & Baby Breath', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 950, stock: 0, supplier: '',
    unsplashId: _pinkRose, imageSeed: 'bouquet-lily'),
  CatalogItem(name: 'Peony Luxe', variety: 'Coral Peonies', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 1800, stock: 0, supplier: '',
    unsplashId: _peony, imageSeed: 'bouquet-peony'),
  CatalogItem(name: 'Sunny Smile', variety: 'Sunflowers & Daisies', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 550, stock: 0, supplier: '',
    unsplashId: _yellow1, imageSeed: 'bouquet-sunny'),
  CatalogItem(name: 'Pastel Garden', variety: 'Pink Mix', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 750, stock: 0, supplier: '',
    unsplashId: _pinkRose, imageSeed: 'bouquet-pastel'),
  CatalogItem(name: 'Tropical Bliss', variety: 'Orchid & Lily', unit: 'piece', category: 'bouquet',
    purchasePrice: 0, sellingPrice: 1200, stock: 0, supplier: '',
    unsplashId: _tulips, imageSeed: 'bouquet-tropical'),
];

String imageUrlFor({String? unsplashId, required String seed, int size = 400}) {
  if (unsplashId != null && unsplashId.isNotEmpty) {
    return 'https://images.unsplash.com/photo-$unsplashId?w=$size&h=$size&fit=crop&auto=format&q=80';
  }
  return 'https://picsum.photos/seed/${Uri.encodeComponent(seed)}/$size/$size';
}

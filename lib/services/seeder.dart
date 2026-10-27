import '../data/api.dart';
import '../data/catalog.dart';
import '../data/models.dart';

class SeedProgress {
  final int done;
  final int total;
  final String current;
  const SeedProgress({required this.done, required this.total, required this.current});
}

class SeedResult {
  final int archived;
  final int inserted;
  final List<String> failures;
  const SeedResult({required this.archived, required this.inserted, required this.failures});
}

/// Wipes current active catalog (archives everything) and seeds the demo set.
Future<SeedResult> seedShowroomCatalog({
  bool wipeExisting = true,
  void Function(SeedProgress)? onProgress,
}) async {
  final failures = <String>[];
  int archived = 0;
  int inserted = 0;

  if (wipeExisting) {
    final List<Product> existing;
    try { existing = await repo.products(); }
    catch (e) { failures.add('read existing: $e'); return SeedResult(archived: 0, inserted: 0, failures: failures); }

    for (int i = 0; i < existing.length; i++) {
      final p = existing[i];
      onProgress?.call(SeedProgress(done: i, total: existing.length, current: 'Archiving ${p.name}'));
      try { await repo.archiveProduct(p.id); archived++; }
      catch (e) { failures.add('archive ${p.name}: $e'); }
    }
  }

  for (int i = 0; i < seedCatalog.length; i++) {
    final c = seedCatalog[i];
    onProgress?.call(SeedProgress(done: i, total: seedCatalog.length, current: 'Adding ${c.name} ${c.variety}'));
    try { await repo.createProduct(c.toInput()); inserted++; }
    catch (e) { failures.add('insert ${c.name} ${c.variety}: $e'); }
  }

  return SeedResult(archived: archived, inserted: inserted, failures: failures);
}

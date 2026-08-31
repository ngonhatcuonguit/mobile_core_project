import 'package:flutter_core_project/features/material_library/models/material_library_item.dart';

abstract class MaterialLibraryStore {
  Future<List<MaterialLibraryItem>> getAll();

  Future<MaterialLibraryItem> create(MaterialLibraryItem item);

  Future<void> update(MaterialLibraryItem item);

  Future<void> delete(int id);
}

/// Lightweight fallback for widget tests and platforms without mobile SQLite.
/// Android and iOS always use [MaterialLibraryDatabase].
class InMemoryMaterialLibraryStore implements MaterialLibraryStore {
  final Map<int, MaterialLibraryItem> _items = {};
  int _nextId = 1;

  @override
  Future<List<MaterialLibraryItem>> getAll() async {
    final items = _items.values.toList();
    items.sort((a, b) {
      final typeComparison = a.type.index.compareTo(b.type.index);
      return typeComparison != 0
          ? typeComparison
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  @override
  Future<MaterialLibraryItem> create(MaterialLibraryItem item) async {
    final saved = item.copyWith(id: _nextId++);
    _items[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> update(MaterialLibraryItem item) async {
    final id = item.id;
    if (id == null || !_items.containsKey(id)) {
      throw StateError('Cannot update an item that does not exist.');
    }
    _items[id] = item;
  }

  @override
  Future<void> delete(int id) async {
    _items.remove(id);
  }
}

import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/repositories/material_library_repository.dart';

class MaterialLibraryRepositoryImpl implements MaterialLibraryRepository {
  const MaterialLibraryRepositoryImpl(this._localDataSource);

  final MaterialLibraryStore _localDataSource;

  @override
  Future<List<MaterialLibraryItem>> getAll() => _localDataSource.getAll();

  @override
  Future<MaterialLibraryItem> create(MaterialLibraryItem item) {
    return _localDataSource.create(item);
  }

  @override
  Future<void> update(MaterialLibraryItem item) {
    return _localDataSource.update(item);
  }

  @override
  Future<void> delete(int id) => _localDataSource.delete(id);
}

import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';

abstract class MaterialLibraryRepository {
  Future<List<MaterialLibraryItem>> getAll();

  Future<MaterialLibraryItem> create(MaterialLibraryItem item);

  Future<void> update(MaterialLibraryItem item);

  Future<void> delete(int id);
}

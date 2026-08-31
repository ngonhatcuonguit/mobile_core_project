import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/repositories/material_library_repository.dart';

class GetMaterialLibraryItems
    implements UseCase<List<MaterialLibraryItem>, NoParams> {
  const GetMaterialLibraryItems(this._repository);

  final MaterialLibraryRepository _repository;

  @override
  Future<List<MaterialLibraryItem>> call(NoParams params) {
    return _repository.getAll();
  }
}

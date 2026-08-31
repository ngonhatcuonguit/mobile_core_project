import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/repositories/material_library_repository.dart';

class SaveMaterialLibraryItem
    implements UseCase<MaterialLibraryItem, SaveMaterialLibraryItemParams> {
  const SaveMaterialLibraryItem(this._repository);

  final MaterialLibraryRepository _repository;

  @override
  Future<MaterialLibraryItem> call(
    SaveMaterialLibraryItemParams params,
  ) async {
    if (params.isEditing) {
      await _repository.update(params.item);
      return params.item;
    }
    return _repository.create(params.item);
  }
}

class SaveMaterialLibraryItemParams extends Equatable {
  const SaveMaterialLibraryItemParams({
    required this.item,
    required this.isEditing,
  });

  final MaterialLibraryItem item;
  final bool isEditing;

  @override
  List<Object?> get props => [item, isEditing];
}

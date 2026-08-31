import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/material_library/domain/repositories/material_library_repository.dart';

class DeleteMaterialLibraryItem
    implements UseCase<void, DeleteMaterialLibraryItemParams> {
  const DeleteMaterialLibraryItem(this._repository);

  final MaterialLibraryRepository _repository;

  @override
  Future<void> call(DeleteMaterialLibraryItemParams params) {
    return _repository.delete(params.id);
  }
}

class DeleteMaterialLibraryItemParams extends Equatable {
  const DeleteMaterialLibraryItemParams(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

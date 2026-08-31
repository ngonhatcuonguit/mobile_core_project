import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/delete_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/get_material_library_items.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/save_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_state.dart';

class MaterialLibraryCubit extends Cubit<MaterialLibraryState> {
  MaterialLibraryCubit({
    required GetMaterialLibraryItems getItems,
    required SaveMaterialLibraryItem saveItem,
    required DeleteMaterialLibraryItem deleteItem,
  })  : _getItems = getItems,
        _saveItem = saveItem,
        _deleteItem = deleteItem,
        super(const MaterialLibraryState());

  final GetMaterialLibraryItems _getItems;
  final SaveMaterialLibraryItem _saveItem;
  final DeleteMaterialLibraryItem _deleteItem;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(
        state.copyWith(
          status: MaterialLibraryStatus.loading,
          clearError: true,
        ),
      );
    }

    try {
      final items = await _getItems(const NoParams());
      emit(
        state.copyWith(
          status: MaterialLibraryStatus.success,
          items: items,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MaterialLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> save(MaterialLibraryItem item, {required bool isEditing}) async {
    try {
      await _saveItem(
        SaveMaterialLibraryItemParams(
          item: item,
          isEditing: isEditing,
        ),
      );
      await load(showLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          status: MaterialLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _deleteItem(DeleteMaterialLibraryItemParams(id));
      await load(showLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          status: MaterialLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }
}

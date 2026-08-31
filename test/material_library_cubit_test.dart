import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_repository_impl.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/delete_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/get_material_library_items.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/save_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_cubit.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_state.dart';
import 'package:flutter_core_project/presentation/pages/main/bloc/main_navigation_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryMaterialLibraryStore store;
  late MaterialLibraryCubit cubit;

  setUp(() {
    store = InMemoryMaterialLibraryStore();
    final repository = MaterialLibraryRepositoryImpl(store);
    cubit = MaterialLibraryCubit(
      getItems: GetMaterialLibraryItems(repository),
      saveItem: SaveMaterialLibraryItem(repository),
      deleteItem: DeleteMaterialLibraryItem(repository),
    );
  });

  tearDown(() => cubit.close());

  blocTest<MainNavigationCubit, int>(
    'navigation emits only valid, changed tab indexes',
    build: MainNavigationCubit.new,
    act: (cubit) {
      cubit
        ..select(1)
        ..select(1)
        ..select(4)
        ..select(3);
    },
    expect: () => [1, 3],
  );

  blocTest<MaterialLibraryCubit, MaterialLibraryState>(
    'load emits loading then the local library',
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => const [
      MaterialLibraryState(status: MaterialLibraryStatus.loading),
      MaterialLibraryState(status: MaterialLibraryStatus.success),
    ],
  );

  test('save and delete update state through use cases', () async {
    await cubit.save(
      const MaterialLibraryItem(
        name: 'Xi mang',
        price: 95000,
        unit: 'package',
        type: LibraryItemType.material,
      ),
      isEditing: false,
    );

    expect(cubit.state.status, MaterialLibraryStatus.success);
    expect(cubit.state.items.single.name, 'Xi mang');

    await cubit.delete(cubit.state.items.single.id!);
    expect(cubit.state.status, MaterialLibraryStatus.success);
    expect(cubit.state.items, isEmpty);
  });
}

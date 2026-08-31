import 'package:flutter_core_project/features/material_library/data/material_library_database.dart';
import 'package:flutter_core_project/features/material_library/models/material_library_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late MaterialLibraryDatabase database;

  setUp(() {
    database = MaterialLibraryDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('SQLite store creates, reads, updates and deletes library items',
      () async {
    final material = await database.create(
      const MaterialLibraryItem(
        name: 'Gạch xây',
        price: 1250,
        unit: 'piece',
        type: LibraryItemType.material,
      ),
    );
    final labor = await database.create(
      const MaterialLibraryItem(
        name: 'Nhân công xây tường',
        price: 350000,
        unit: 'm2',
        type: LibraryItemType.labor,
      ),
    );

    expect(material.id, isNotNull);
    expect(labor.id, isNotNull);
    var items = await database.getAll();
    expect(items, hasLength(2));
    expect(items.first.type, LibraryItemType.labor);
    expect(items.last.type, LibraryItemType.material);

    await database.update(
      material.copyWith(name: 'Gạch xây mới', price: 1500, unit: 'box'),
    );
    items = await database.getAll();
    final updated = items.firstWhere((item) => item.id == material.id);
    expect(updated.name, 'Gạch xây mới');
    expect(updated.price, 1500);
    expect(updated.unit, 'box');

    await database.delete(labor.id!);
    items = await database.getAll();
    expect(items, hasLength(1));
    expect(items.single.id, material.id);
  });
}

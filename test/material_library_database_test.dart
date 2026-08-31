import 'dart:io';

import 'package:flutter_core_project/features/material_library/data/material_library_database.dart';
import 'package:flutter_core_project/features/material_library/models/material_library_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_util;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late MaterialLibraryDatabase database;
  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'construction_plan_material_library_test_',
    );
    databasePath = path_util.join(temporaryDirectory.path, 'library.db');
    database = MaterialLibraryDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await database.close();
    await databaseFactoryFfi.deleteDatabase(databasePath);
    await temporaryDirectory.delete(recursive: true);
  });

  test('SQLite store creates, reads, updates and deletes library items',
      () async {
    final material = await database.create(
      const MaterialLibraryItem(
        name: 'Gạch xây',
        price: 1250,
        unit: 'piece',
        type: LibraryItemType.material,
        length: 0.2,
        width: 0.2,
        height: 0.1,
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
    expect(items.last.hasPieceDimensions, isTrue);
    expect(items.last.length, 0.2);
    expect(items.last.width, 0.2);
    expect(items.last.height, 0.1);

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

  test('SQLite migrates existing version 1 items without data loss', () async {
    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE material_library_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              price REAL NOT NULL CHECK(price >= 0),
              unit TEXT NOT NULL,
              type TEXT NOT NULL CHECK(type IN ('material', 'labor'))
            )
          ''');
          await db.insert('material_library_items', {
            'name': 'Gạch cũ',
            'price': 1000,
            'unit': 'piece',
            'type': 'material',
          });
        },
      ),
    );
    await legacyDatabase.close();

    final items = await database.getAll();
    expect(items, hasLength(1));
    expect(items.single.name, 'Gạch cũ');
    expect(items.single.length, isNull);
    expect(items.single.width, isNull);
    expect(items.single.height, isNull);
  });
}

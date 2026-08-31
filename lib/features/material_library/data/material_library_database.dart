import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/material_library/models/material_library_item.dart';
import 'package:path/path.dart' as path_util;
import 'package:sqflite/sqflite.dart';

class MaterialLibraryDatabase implements MaterialLibraryStore {
  MaterialLibraryDatabase({
    DatabaseFactory? factory,
    String? databasePath,
  })  : _databaseFactory = factory ?? databaseFactory,
        _databasePath = databasePath;

  static final MaterialLibraryDatabase instance = MaterialLibraryDatabase();

  static const _databaseName = 'construction_plan.db';
  static const _databaseVersion = 2;
  static const _tableName = 'material_library_items';

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get _db async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final resolvedPath = _databasePath ??
        path_util.join(
            await _databaseFactory.getDatabasesPath(), _databaseName);
    final opened = await _databaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE $_tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              price REAL NOT NULL CHECK(price >= 0),
              unit TEXT NOT NULL,
              type TEXT NOT NULL CHECK(type IN ('material', 'labor')),
              length REAL,
              width REAL,
              height REAL
            )
          ''');
          await database.execute(
            'CREATE INDEX idx_${_tableName}_type_name '
            'ON $_tableName(type, name COLLATE NOCASE)',
          );
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await database.execute(
              'ALTER TABLE $_tableName ADD COLUMN length REAL',
            );
            await database.execute(
              'ALTER TABLE $_tableName ADD COLUMN width REAL',
            );
            await database.execute(
              'ALTER TABLE $_tableName ADD COLUMN height REAL',
            );
          }
        },
      ),
    );
    _database = opened;
    return opened;
  }

  @override
  Future<List<MaterialLibraryItem>> getAll() async {
    final rows = await (await _db).query(
      _tableName,
      orderBy: 'type ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(MaterialLibraryItem.fromDatabaseMap).toList();
  }

  @override
  Future<MaterialLibraryItem> create(MaterialLibraryItem item) async {
    final id = await (await _db).insert(
      _tableName,
      item.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return item.copyWith(id: id);
  }

  @override
  Future<void> update(MaterialLibraryItem item) async {
    final id = item.id;
    if (id == null) {
      throw ArgumentError('An ID is required to update a library item.');
    }
    final changed = await (await _db).update(
      _tableName,
      item.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    if (changed == 0) {
      throw StateError('Library item $id does not exist.');
    }
  }

  @override
  Future<void> delete(int id) async {
    await (await _db).delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final current = _database;
    if (current != null && current.isOpen) await current.close();
    _database = null;
  }
}

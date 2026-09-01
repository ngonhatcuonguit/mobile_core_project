import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:path/path.dart' as path_util;
import 'package:sqflite/sqflite.dart';

class ProjectDatabase implements ProjectStore {
  ProjectDatabase({DatabaseFactory? factory, String? databasePath})
      : _databaseFactory = factory ?? databaseFactory,
        _databasePath = databasePath;

  static final ProjectDatabase instance = ProjectDatabase();

  static const _databaseName = 'construction_projects.db';
  static const _databaseVersion = 1;

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get _db async {
    final current = _database;
    if (current != null && current.isOpen) return current;

    final resolvedPath = _databasePath ??
        path_util.join(
          await _databaseFactory.getDatabasesPath(),
          _databaseName,
        );
    final opened = await _databaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
      ),
    );
    _database = opened;
    return opened;
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE project_floors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        floor_number INTEGER NOT NULL,
        length REAL NOT NULL CHECK(length > 0),
        width REAL NOT NULL CHECK(width > 0),
        height REAL NOT NULL CHECK(height > 0),
        UNIQUE(project_id, floor_number)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_roofs (
        project_id TEXT PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
        roof_type TEXT NOT NULL,
        length REAL NOT NULL CHECK(length > 0),
        width REAL NOT NULL CHECK(width > 0),
        height REAL NOT NULL CHECK(height >= 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_foundation_structures (
        project_id TEXT PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
        foundation_type TEXT NOT NULL,
        structure_type TEXT NOT NULL,
        alignment TEXT,
        main_bar_diameter INTEGER NOT NULL CHECK(main_bar_diameter > 0),
        isolated_length REAL,
        isolated_width REAL,
        isolated_height REAL
      )
    ''');
    await database.execute('''
      CREATE TABLE project_columns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        width REAL NOT NULL CHECK(width > 0),
        thickness REAL NOT NULL CHECK(thickness > 0),
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        main_bars_count INTEGER NOT NULL CHECK(main_bars_count > 0),
        main_bar_diameter INTEGER NOT NULL CHECK(main_bar_diameter > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_pile_caps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        length REAL NOT NULL CHECK(length > 0),
        width REAL NOT NULL CHECK(width > 0),
        height REAL NOT NULL CHECK(height > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        selection_key TEXT NOT NULL,
        source_library_id INTEGER,
        catalog_code TEXT,
        name_snapshot TEXT NOT NULL,
        unit_snapshot TEXT NOT NULL,
        unit_price_snapshot REAL NOT NULL CHECK(unit_price_snapshot >= 0),
        item_type TEXT NOT NULL,
        UNIQUE(project_id, selection_key)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_foundation_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        length REAL NOT NULL CHECK(length > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_walls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        wall_type TEXT NOT NULL,
        plaster_sides INTEGER NOT NULL CHECK(plaster_sides BETWEEN 0 AND 2),
        length REAL NOT NULL CHECK(length > 0),
        height REAL NOT NULL CHECK(height > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_openings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        opening_type TEXT NOT NULL,
        width REAL NOT NULL CHECK(width > 0),
        height REAL NOT NULL CHECK(height > 0),
        quantity INTEGER NOT NULL CHECK(quantity > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_bathrooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        area REAL NOT NULL CHECK(area > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE project_stairs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL,
        steps INTEGER NOT NULL CHECK(steps > 0)
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_projects_updated_at ON projects(updated_at DESC)',
    );
  }

  @override
  Future<List<ConstructionProject>> getAll() async {
    final database = await _db;
    final projectRows = await database.query(
      'projects',
      orderBy: 'updated_at DESC',
    );
    final projects = <ConstructionProject>[];
    for (final row in projectRows) {
      projects.add(await _readProject(database, row));
    }
    return projects;
  }

  Future<ConstructionProject> _readProject(
    Database database,
    Map<String, Object?> row,
  ) async {
    final id = row['id']! as String;
    final results = await Future.wait([
      database.query(
        'project_floors',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'floor_number',
      ),
      database.query(
        'project_roofs',
        where: 'project_id = ?',
        whereArgs: [id],
        limit: 1,
      ),
      database.query(
        'project_foundation_structures',
        where: 'project_id = ?',
        whereArgs: [id],
        limit: 1,
      ),
      database.query(
        'project_columns',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_pile_caps',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_materials',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'id',
      ),
      database.query(
        'project_foundation_segments',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_walls',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_openings',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_bathrooms',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
      database.query(
        'project_stairs',
        where: 'project_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order',
      ),
    ]);
    final roof = results[1].single;
    final foundation = results[2].single;
    return ConstructionProject(
      id: id,
      name: row['name']! as String,
      location: row['location']! as String,
      imagePath: row['image_path'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      floors: results[0]
          .map(
            (item) => BuildingFloor(
              number: item['floor_number']! as int,
              length: (item['length']! as num).toDouble(),
              width: (item['width']! as num).toDouble(),
              height: (item['height']! as num).toDouble(),
            ),
          )
          .toList(),
      roof: RoofSpec(
        type: _enumByName(RoofType.values, roof['roof_type']! as String),
        length: (roof['length']! as num).toDouble(),
        width: (roof['width']! as num).toDouble(),
        height: (roof['height']! as num).toDouble(),
      ),
      foundationStructure: FoundationStructureSpec(
        foundationType: _enumByName(
          FoundationType.values,
          foundation['foundation_type']! as String,
        ),
        structureType: _enumByName(
          StructureType.values,
          foundation['structure_type']! as String,
        ),
        alignment: foundation['alignment'] == null
            ? null
            : _enumByName(
                FoundationAlignment.values,
                foundation['alignment']! as String,
              ),
        mainBarDiameter: foundation['main_bar_diameter']! as int,
        isolatedLength: (foundation['isolated_length'] as num?)?.toDouble(),
        isolatedWidth: (foundation['isolated_width'] as num?)?.toDouble(),
        isolatedHeight: (foundation['isolated_height'] as num?)?.toDouble(),
        columns: results[3]
            .map(
              (item) => ColumnSpec(
                width: (item['width']! as num).toDouble(),
                thickness: (item['thickness']! as num).toDouble(),
                quantity: item['quantity']! as int,
                mainBarsCount: item['main_bars_count']! as int,
                mainBarDiameter: item['main_bar_diameter']! as int,
              ),
            )
            .toList(),
        pileCaps: results[4]
            .map(
              (item) => PileCapSpec(
                length: (item['length']! as num).toDouble(),
                width: (item['width']! as num).toDouble(),
                height: (item['height']! as num).toDouble(),
              ),
            )
            .toList(),
      ),
      materials: results[5]
          .map(
            (item) => ProjectMaterial(
              selectionKey: item['selection_key']! as String,
              sourceLibraryId: item['source_library_id'] as int?,
              catalogCode: item['catalog_code'] as String?,
              name: item['name_snapshot']! as String,
              unit: item['unit_snapshot']! as String,
              unitPrice: (item['unit_price_snapshot']! as num).toDouble(),
              type: _enumByName(
                ProjectMaterialType.values,
                item['item_type']! as String,
              ),
            ),
          )
          .toList(),
      details: ProjectDetails(
        foundationSegments: results[6]
            .map(
              (item) => FoundationSegment(
                (item['length']! as num).toDouble(),
              ),
            )
            .toList(),
        walls: results[7]
            .map(
              (item) => WallSpec(
                type: _enumByName(
                  WallType.values,
                  item['wall_type']! as String,
                ),
                plasterSides: item['plaster_sides']! as int,
                length: (item['length']! as num).toDouble(),
                height: (item['height']! as num).toDouble(),
              ),
            )
            .toList(),
        openings: results[8]
            .map(
              (item) => OpeningSpec(
                type: _enumByName(
                  OpeningType.values,
                  item['opening_type']! as String,
                ),
                width: (item['width']! as num).toDouble(),
                height: (item['height']! as num).toDouble(),
                quantity: item['quantity']! as int,
              ),
            )
            .toList(),
        bathrooms: results[9]
            .map(
              (item) => BathroomSpec((item['area']! as num).toDouble()),
            )
            .toList(),
        stairs: results[10]
            .map((item) => StairSpec(item['steps']! as int))
            .toList(),
      ),
    );
  }

  @override
  Future<void> save(ConstructionProject project) async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.insert(
        'projects',
        {
          'id': project.id,
          'name': project.name,
          'location': project.location,
          'image_path': project.imagePath,
          'created_at': project.createdAt.toIso8601String(),
          'updated_at': project.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final batch = transaction.batch();
      for (final floor in project.floors) {
        batch.insert('project_floors', {
          'project_id': project.id,
          'floor_number': floor.number,
          'length': floor.length,
          'width': floor.width,
          'height': floor.height,
        });
      }
      batch.insert('project_roofs', {
        'project_id': project.id,
        'roof_type': project.roof.type.name,
        'length': project.roof.length,
        'width': project.roof.width,
        'height': project.roof.height,
      });
      final foundation = project.foundationStructure;
      batch.insert('project_foundation_structures', {
        'project_id': project.id,
        'foundation_type': foundation.foundationType.name,
        'structure_type': foundation.structureType.name,
        'alignment': foundation.alignment?.name,
        'main_bar_diameter': foundation.mainBarDiameter,
        'isolated_length': foundation.isolatedLength,
        'isolated_width': foundation.isolatedWidth,
        'isolated_height': foundation.isolatedHeight,
      });
      for (var index = 0; index < foundation.columns.length; index++) {
        final column = foundation.columns[index];
        batch.insert('project_columns', {
          'project_id': project.id,
          'sort_order': index,
          'width': column.width,
          'thickness': column.thickness,
          'quantity': column.quantity,
          'main_bars_count': column.mainBarsCount,
          'main_bar_diameter': column.mainBarDiameter,
        });
      }
      for (var index = 0; index < foundation.pileCaps.length; index++) {
        final cap = foundation.pileCaps[index];
        batch.insert('project_pile_caps', {
          'project_id': project.id,
          'sort_order': index,
          'length': cap.length,
          'width': cap.width,
          'height': cap.height,
        });
      }
      for (final material in project.materials) {
        batch.insert('project_materials', {
          'project_id': project.id,
          'selection_key': material.selectionKey,
          'source_library_id': material.sourceLibraryId,
          'catalog_code': material.catalogCode,
          'name_snapshot': material.name,
          'unit_snapshot': material.unit,
          'unit_price_snapshot': material.unitPrice,
          'item_type': material.type.name,
        });
      }
      for (var index = 0;
          index < project.details.foundationSegments.length;
          index++) {
        batch.insert('project_foundation_segments', {
          'project_id': project.id,
          'sort_order': index,
          'length': project.details.foundationSegments[index].length,
        });
      }
      for (var index = 0; index < project.details.walls.length; index++) {
        final wall = project.details.walls[index];
        batch.insert('project_walls', {
          'project_id': project.id,
          'sort_order': index,
          'wall_type': wall.type.name,
          'plaster_sides': wall.plasterSides,
          'length': wall.length,
          'height': wall.height,
        });
      }
      for (var index = 0; index < project.details.openings.length; index++) {
        final opening = project.details.openings[index];
        batch.insert('project_openings', {
          'project_id': project.id,
          'sort_order': index,
          'opening_type': opening.type.name,
          'width': opening.width,
          'height': opening.height,
          'quantity': opening.quantity,
        });
      }
      for (var index = 0; index < project.details.bathrooms.length; index++) {
        batch.insert('project_bathrooms', {
          'project_id': project.id,
          'sort_order': index,
          'area': project.details.bathrooms[index].area,
        });
      }
      for (var index = 0; index < project.details.stairs.length; index++) {
        batch.insert('project_stairs', {
          'project_id': project.id,
          'sort_order': index,
          'steps': project.details.stairs[index].steps,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> delete(String id) async {
    await (await _db).delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final current = _database;
    if (current != null && current.isOpen) await current.close();
    _database = null;
  }
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  return values.firstWhere((value) => value.name == name);
}

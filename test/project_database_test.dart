import 'dart:io';

import 'package:flutter_core_project/features/projects/data/project_database.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_util;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late ProjectDatabase database;
  late Directory temporaryDirectory;
  late String databasePath;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'construction_plan_project_test_',
    );
    databasePath = path_util.join(temporaryDirectory.path, 'projects.db');
    database = ProjectDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await database.close();
    await databaseFactoryFfi.deleteDatabase(databasePath);
    await temporaryDirectory.delete(recursive: true);
  });

  test('SQLite preserves the normalized project aggregate', () async {
    final createdAt = DateTime.utc(2026, 8, 31, 8);
    final project = ConstructionProject(
      id: 'project-1',
      name: 'Nhà phố Bình An',
      location: 'Thành phố Thủ Đức, Thành phố Hồ Chí Minh',
      provinceId: 'ho_chi_minh_city',
      provinceName: 'Thành phố Hồ Chí Minh',
      districtId: '769',
      districtName: 'Thành phố Thủ Đức',
      imagePath: '/tmp/project.jpg',
      createdAt: createdAt,
      updatedAt: createdAt,
      floors: const [
        BuildingFloor(number: 1, length: 10, width: 5, height: 3.3),
        BuildingFloor(number: 2, length: 9, width: 5, height: 3.3),
      ],
      roof: const RoofSpec(
        type: RoofType.tile,
        length: 10,
        width: 5,
        height: 2,
      ),
      foundationStructure: const FoundationStructureSpec(
        foundationType: FoundationType.pile,
        structureType: StructureType.reinforcedConcrete,
        mainBarDiameter: 18,
        columns: [
          ColumnSpec(
            width: 0.2,
            thickness: 0.25,
            quantity: 8,
            mainBarsCount: 6,
            mainBarDiameter: 18,
          ),
        ],
        pileCaps: [
          PileCapSpec(length: 1.4, width: 1.2, height: 0.5),
        ],
      ),
      materials: const [
        ProjectMaterial(
          selectionKey: 'library:12',
          sourceLibraryId: 12,
          name: 'Xi măng PCB40',
          unit: 'package',
          unitPrice: 95000,
          type: ProjectMaterialType.material,
        ),
      ],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(22.5)],
        walls: [
          WallSpec(
            type: WallType.wall200,
            plasterSides: 2,
            length: 18,
            height: 3.3,
          ),
        ],
        openings: [
          OpeningSpec(
            type: OpeningType.window,
            width: 1.2,
            height: 1.4,
            quantity: 4,
          ),
        ],
        bathrooms: [BathroomSpec(4.5)],
        stairs: [StairSpec(19)],
      ),
    );

    await database.save(project);
    final loaded = (await database.getAll()).single;

    expect(loaded, project);
    expect(loaded.provinceId, 'ho_chi_minh_city');
    expect(loaded.districtId, '769');
    expect(loaded.totalFloorArea, 95);
    expect(loaded.details.walls.single.area, closeTo(59.4, 0.001));
    expect(loaded.details.openings.single.area, closeTo(6.72, 0.001));

    final updated = project.copyWith(
      name: 'Nhà phố Bình An cập nhật',
      location: 'Thành phố Hồ Chí Minh',
      updatedAt: createdAt.add(const Duration(days: 1)),
    );
    await database.save(updated);
    final reloaded = (await database.getAll()).single;

    expect(reloaded, updated);
    expect(reloaded.floors, hasLength(2));
    expect(reloaded.foundationStructure.columns, hasLength(1));
    expect(reloaded.details.walls, hasLength(1));

    await database.delete(project.id);
    expect(await database.getAll(), isEmpty);
  });
}

import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/core/data/vietnam_provinces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProjectWizardCubit cubit;

  setUp(() => cubit = ProjectWizardCubit());
  tearDown(() => cubit.close());

  test('province catalog contains all current provincial-level units', () {
    expect(vietnamProvinces, hasLength(34));
    expect(
      vietnamProvinces.map((province) => province.id).toSet(),
      hasLength(34),
    );
    expect(
      vietnamProvinces.where((province) => province.isMunicipality),
      hasLength(6),
    );
  });

  test('wizard enforces the five business validation steps', () {
    expect(cubit.next(), isFalse);
    expect(cubit.state.showValidation, isTrue);

    cubit.updateBasicInfo(name: 'Nhà phố mới', location: 'Đà Nẵng');
    expect(cubit.next(), isTrue);
    expect(cubit.state.currentStep, 1);

    cubit.updateFloor(
      0,
      const BuildingFloor(number: 1, length: 10, width: 5, height: 3.3),
    );
    cubit.updateRoof(
      const RoofSpec(type: RoofType.flat, length: 10, width: 5, height: 0.3),
    );
    expect(cubit.next(), isTrue);

    cubit.selectFoundationType(FoundationType.strip);
    cubit.selectStructureType(StructureType.reinforcedConcrete);
    expect(cubit.next(), isTrue);

    cubit.toggleMaterial(
      const ProjectMaterial(
        selectionKey: 'catalog:brick',
        catalogCode: 'brick',
        name: 'Gạch xây',
        unit: 'piece',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
    );
    expect(cubit.next(), isTrue);

    cubit.updateDetails(
      const ProjectDetails(foundationSegments: [FoundationSegment(20)]),
    );
    expect(cubit.state.canComplete, isTrue);

    final project = cubit.buildProject();
    expect(project.name, 'Nhà phố mới');
    expect(project.floors.single.area, 50);
    expect(project.materials.single.catalogCode, 'brick');
    expect(project.foundationStructure.columns, isNotEmpty);
  });
}

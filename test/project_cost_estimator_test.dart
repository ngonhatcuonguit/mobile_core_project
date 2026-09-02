import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/project_cost_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const estimator = ProjectCostEstimator();

  test('preserves legacy 80 m2 quantities with current price snapshots', () {
    final estimate = estimator.estimate(_project(areaLength: 10, areaWidth: 8));

    expect(estimate.lines[0].quantity, 12800);
    expect(estimate.lines[1].quantity, 5.4);
    expect(estimate.lines[2].quantity, 1.8);
    expect(estimate.lines[3].quantity, 80);
    expect(estimate.totalCost, 169320000);
    expect(estimate.linesByCost.first.material.catalogCode, 'labor');
  });

  test('scales deterministic quantities with the current total floor area', () {
    final estimate = estimator.estimate(_project(areaLength: 20, areaWidth: 8));

    expect(estimate.lines[0].quantity, 25600);
    expect(estimate.lines[3].quantity, 160);
    expect(estimate.totalCost, 338640000);
  });
}

ConstructionProject _project({
  required double areaLength,
  required double areaWidth,
}) {
  final now = DateTime(2026, 9, 1);
  return ConstructionProject(
    id: 'estimate-project',
    name: 'Estimate project',
    location: 'Da Nang',
    createdAt: now,
    updatedAt: now,
    floors: [
      BuildingFloor(
        number: 1,
        length: areaLength,
        width: areaWidth,
        height: 3.2,
      ),
    ],
    roof: RoofSpec(
      type: RoofType.tile,
      length: areaLength,
      width: areaWidth,
      height: 2,
    ),
    foundationStructure: const FoundationStructureSpec(
      foundationType: FoundationType.strip,
      structureType: StructureType.reinforcedConcrete,
    ),
    materials: const [
      ProjectMaterial(
        selectionKey: 'catalog:brick',
        catalogCode: 'brick',
        name: 'Gạch xây',
        unit: 'piece',
        unitPrice: 1500,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:cement',
        catalogCode: 'cement',
        name: 'Xi măng',
        unit: 'ton',
        unitPrice: 1800000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:steel',
        catalogCode: 'steel',
        name: 'Sắt thép',
        unit: 'ton',
        unitPrice: 18000000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:labor',
        catalogCode: 'labor',
        name: 'Nhân công xây dựng',
        unit: 'm2',
        unitPrice: 1350000,
        type: ProjectMaterialType.labor,
      ),
    ],
    details: const ProjectDetails(),
  );
}

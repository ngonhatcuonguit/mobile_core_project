import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

class ProjectCostLine extends Equatable {
  const ProjectCostLine({
    required this.material,
    required this.quantity,
  });

  final ProjectMaterial material;
  final double quantity;

  double get amount => material.unitPrice * quantity;

  @override
  List<Object?> get props => [material, quantity];
}

class ProjectCostEstimate extends Equatable {
  const ProjectCostEstimate(this.lines);

  final List<ProjectCostLine> lines;

  double get totalCost => lines.fold(0, (sum, line) => sum + line.amount);

  List<ProjectCostLine> get linesByCost {
    final sorted = [...lines]
      ..sort((left, right) => right.amount.compareTo(left.amount));
    return sorted;
  }

  @override
  List<Object?> get props => [lines];
}

/// Keeps the legacy detail screen's deterministic UI estimate contract.
///
/// Legacy fixtures described an 80 m2 sample project. Scaling them by the
/// current floor area preserves those familiar quantities while making the
/// estimate useful for projects stored in the new SQLite model. This is not a
/// replacement for the future engineering calculation API.
class ProjectCostEstimator {
  const ProjectCostEstimator();

  static const double _baselineArea = 80;

  static const Map<String, double> _baselineQuantities = {
    'brick': 12800,
    'sand': 12,
    'plaster_sand': 8,
    'concrete_sand': 9,
    'cement': 5.4,
    'steel': 1.8,
    'stone': 15,
    'tile': 96,
    'roof_tile': 120,
    'metal_sheet': 150,
    'insulated_metal_sheet': 140,
    'gypsum': 110,
    'exterior_paint': 160,
    'interior_paint': 180,
    'aluminum_door': 24,
    'composite_door': 10,
    'labor': 80,
    'plumbing_labor': 90,
    'plumbing_material': 60,
  };

  ProjectCostEstimate estimate(ConstructionProject project) {
    final scale = project.totalFloorArea <= 0
        ? 1.0
        : project.totalFloorArea / _baselineArea;
    return ProjectCostEstimate(
      project.materials
          .map(
            (material) => ProjectCostLine(
              material: material,
              quantity: _quantityFor(material, scale),
            ),
          )
          .toList(growable: false),
    );
  }

  double _quantityFor(ProjectMaterial material, double scale) {
    final catalogCode = material.catalogCode;
    final baseline =
        catalogCode == null ? null : _baselineQuantities[catalogCode];
    if (baseline != null) return baseline * scale;

    final normalizedUnit = material.unit.toLowerCase().trim();
    if (material.type == ProjectMaterialType.labor ||
        normalizedUnit == 'm2' ||
        normalizedUnit.contains('m²')) {
      return _baselineArea * scale;
    }

    final hash = material.name.codeUnits.fold<int>(
      0,
      (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
    );
    return (50 + hash % 50) * scale;
  }
}

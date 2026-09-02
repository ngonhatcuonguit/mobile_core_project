import 'package:equatable/equatable.dart';

enum RoofType { flat, metal, tile }

enum FoundationType { strip, raft, isolated, pile }

enum StructureType { reinforcedConcrete, steelFrame, masonry, timber }

enum FoundationAlignment { balanced, offsetOneSide, offsetTwoSides }

enum WallType { wall100, wall200 }

enum OpeningType { window, door, rollingDoor }

enum ProjectMaterialType { material, labor }

class BuildingFloor extends Equatable {
  const BuildingFloor({
    required this.number,
    required this.length,
    required this.width,
    required this.height,
  });

  final int number;
  final double length;
  final double width;
  final double height;

  double get area => length * width;

  @override
  List<Object?> get props => [number, length, width, height];
}

class RoofSpec extends Equatable {
  const RoofSpec({
    required this.type,
    required this.length,
    required this.width,
    required this.height,
  });

  final RoofType type;
  final double length;
  final double width;
  final double height;

  double get area => length * width;

  @override
  List<Object?> get props => [type, length, width, height];
}

class ColumnSpec extends Equatable {
  const ColumnSpec({
    required this.width,
    required this.thickness,
    required this.quantity,
    required this.mainBarsCount,
    required this.mainBarDiameter,
  });

  final double width;
  final double thickness;
  final int quantity;
  final int mainBarsCount;
  final int mainBarDiameter;

  @override
  List<Object?> get props => [
        width,
        thickness,
        quantity,
        mainBarsCount,
        mainBarDiameter,
      ];
}

class PileCapSpec extends Equatable {
  const PileCapSpec({
    required this.length,
    required this.width,
    required this.height,
  });

  final double length;
  final double width;
  final double height;

  @override
  List<Object?> get props => [length, width, height];
}

class FoundationStructureSpec extends Equatable {
  const FoundationStructureSpec({
    required this.foundationType,
    required this.structureType,
    this.alignment,
    this.mainBarDiameter = 16,
    this.isolatedLength,
    this.isolatedWidth,
    this.isolatedHeight,
    this.columns = const [],
    this.pileCaps = const [],
  });

  final FoundationType foundationType;
  final StructureType structureType;
  final FoundationAlignment? alignment;
  final int mainBarDiameter;
  final double? isolatedLength;
  final double? isolatedWidth;
  final double? isolatedHeight;
  final List<ColumnSpec> columns;
  final List<PileCapSpec> pileCaps;

  FoundationStructureSpec copyWith({
    FoundationType? foundationType,
    StructureType? structureType,
    FoundationAlignment? alignment,
    int? mainBarDiameter,
    double? isolatedLength,
    double? isolatedWidth,
    double? isolatedHeight,
    List<ColumnSpec>? columns,
    List<PileCapSpec>? pileCaps,
  }) {
    return FoundationStructureSpec(
      foundationType: foundationType ?? this.foundationType,
      structureType: structureType ?? this.structureType,
      alignment: alignment ?? this.alignment,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
      isolatedLength: isolatedLength ?? this.isolatedLength,
      isolatedWidth: isolatedWidth ?? this.isolatedWidth,
      isolatedHeight: isolatedHeight ?? this.isolatedHeight,
      columns: columns ?? this.columns,
      pileCaps: pileCaps ?? this.pileCaps,
    );
  }

  @override
  List<Object?> get props => [
        foundationType,
        structureType,
        alignment,
        mainBarDiameter,
        isolatedLength,
        isolatedWidth,
        isolatedHeight,
        columns,
        pileCaps,
      ];
}

class ProjectMaterial extends Equatable {
  const ProjectMaterial({
    required this.selectionKey,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.type,
    this.sourceLibraryId,
    this.catalogCode,
  });

  final String selectionKey;
  final int? sourceLibraryId;
  final String? catalogCode;
  final String name;
  final String unit;
  final double unitPrice;
  final ProjectMaterialType type;

  @override
  List<Object?> get props => [
        selectionKey,
        sourceLibraryId,
        catalogCode,
        name,
        unit,
        unitPrice,
        type,
      ];
}

class FoundationSegment extends Equatable {
  const FoundationSegment(this.length);

  final double length;

  @override
  List<Object?> get props => [length];
}

class WallSpec extends Equatable {
  const WallSpec({
    required this.type,
    required this.plasterSides,
    required this.length,
    required this.height,
  });

  final WallType type;
  final int plasterSides;
  final double length;
  final double height;

  double get area => length * height;

  @override
  List<Object?> get props => [type, plasterSides, length, height];
}

class OpeningSpec extends Equatable {
  const OpeningSpec({
    required this.type,
    required this.width,
    required this.height,
    required this.quantity,
  });

  final OpeningType type;
  final double width;
  final double height;
  final int quantity;

  double get area => width * height * quantity;

  @override
  List<Object?> get props => [type, width, height, quantity];
}

class BathroomSpec extends Equatable {
  const BathroomSpec(this.area);

  final double area;

  @override
  List<Object?> get props => [area];
}

class StairSpec extends Equatable {
  const StairSpec(this.steps);

  final int steps;

  @override
  List<Object?> get props => [steps];
}

class ProjectDetails extends Equatable {
  const ProjectDetails({
    this.foundationSegments = const [],
    this.walls = const [],
    this.openings = const [],
    this.bathrooms = const [],
    this.stairs = const [],
  });

  final List<FoundationSegment> foundationSegments;
  final List<WallSpec> walls;
  final List<OpeningSpec> openings;
  final List<BathroomSpec> bathrooms;
  final List<StairSpec> stairs;

  bool get isNotEmpty =>
      foundationSegments.isNotEmpty ||
      walls.isNotEmpty ||
      openings.isNotEmpty ||
      bathrooms.isNotEmpty ||
      stairs.isNotEmpty;

  @override
  List<Object?> get props => [
        foundationSegments,
        walls,
        openings,
        bathrooms,
        stairs,
      ];
}

class ConstructionProject extends Equatable {
  const ConstructionProject({
    required this.id,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.floors,
    required this.roof,
    required this.foundationStructure,
    required this.materials,
    required this.details,
    this.imagePath,
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
  });

  final String id;
  final String name;
  final String location;
  final String? imagePath;
  final String? provinceId;
  final String? provinceName;
  final String? districtId;
  final String? districtName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BuildingFloor> floors;
  final RoofSpec roof;
  final FoundationStructureSpec foundationStructure;
  final List<ProjectMaterial> materials;
  final ProjectDetails details;

  double get totalFloorArea => floors.fold(0, (sum, floor) => sum + floor.area);

  ConstructionProject copyWith({
    String? name,
    String? location,
    String? imagePath,
    String? provinceId,
    String? provinceName,
    String? districtId,
    String? districtName,
    DateTime? updatedAt,
    List<BuildingFloor>? floors,
    RoofSpec? roof,
    FoundationStructureSpec? foundationStructure,
    List<ProjectMaterial>? materials,
    ProjectDetails? details,
  }) {
    return ConstructionProject(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
      provinceId: provinceId ?? this.provinceId,
      provinceName: provinceName ?? this.provinceName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      floors: floors ?? this.floors,
      roof: roof ?? this.roof,
      foundationStructure: foundationStructure ?? this.foundationStructure,
      materials: materials ?? this.materials,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        imagePath,
        provinceId,
        provinceName,
        districtId,
        districtName,
        createdAt,
        updatedAt,
        floors,
        roof,
        foundationStructure,
        materials,
        details,
      ];
}

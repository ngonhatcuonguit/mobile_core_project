import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/data/vietnam_districts.dart';
import 'package:flutter_core_project/core/data/vietnam_provinces.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';

class ProjectWizardCubit extends Cubit<ProjectWizardState> {
  ProjectWizardCubit({ConstructionProject? initialProject})
      : _initialProject = initialProject,
        super(
          initialProject == null
              ? const ProjectWizardState()
              : ProjectWizardState.fromProject(initialProject),
        );

  final ConstructionProject? _initialProject;

  bool get isEditing => _initialProject != null;

  String? get originalImagePath => _initialProject?.imagePath;

  void updateBasicInfo({String? name, String? location}) {
    emit(
      state.copyWith(
        name: name,
        location: location,
        showValidation: false,
      ),
    );
  }

  void selectProvince(VietnamProvince province) {
    final changedProvince = state.provinceId != province.id;
    emit(
      state.copyWith(
        location: changedProvince
            ? province.name
            : state.districtName == null
                ? province.name
                : '${state.districtName}, ${province.name}',
        provinceId: province.id,
        provinceName: province.name,
        clearDistrict: changedProvince,
        showValidation: false,
      ),
    );
  }

  void selectDistrict(VietnamDistrict district) {
    final provinceName = state.provinceName;
    if (provinceName == null) return;
    emit(
      state.copyWith(
        location: '${district.name}, $provinceName',
        districtId: district.id,
        districtName: district.name,
        showValidation: false,
      ),
    );
  }

  void setImage(String? path) {
    emit(
      path == null
          ? state.copyWith(clearImage: true)
          : state.copyWith(imagePath: path),
    );
  }

  void updateFloor(int index, BuildingFloor floor) {
    final floors = [...state.floors]..[index] = floor;
    emit(state.copyWith(floors: floors, showValidation: false));
  }

  void addFloor() {
    emit(
      state.copyWith(
        floors: [
          ...state.floors,
          BuildingFloor(
            number: state.floors.length + 1,
            length: 0,
            width: 0,
            height: 0,
          ),
        ],
      ),
    );
  }

  void removeFloor(int index) {
    if (state.floors.length == 1) return;
    final floors = [...state.floors]..removeAt(index);
    emit(
      state.copyWith(
        floors: [
          for (var i = 0; i < floors.length; i++)
            BuildingFloor(
              number: i + 1,
              length: floors[i].length,
              width: floors[i].width,
              height: floors[i].height,
            ),
        ],
      ),
    );
  }

  void updateRoof(RoofSpec roof) {
    emit(state.copyWith(roof: roof, showValidation: false));
  }

  void selectFoundationType(FoundationType type) {
    final defaultColumn = state.columns.isEmpty
        ? const [
            ColumnSpec(
              width: 0.2,
              thickness: 0.2,
              quantity: 4,
              mainBarsCount: 4,
              mainBarDiameter: 16,
            ),
          ]
        : state.columns;
    emit(
      state.copyWith(
        foundationType: type,
        alignment: type == FoundationType.strip
            ? state.alignment ?? FoundationAlignment.balanced
            : state.alignment,
        clearAlignment: type != FoundationType.strip,
        isolatedLength: type == FoundationType.isolated
            ? state.isolatedLength ?? 1.2
            : null,
        isolatedWidth:
            type == FoundationType.isolated ? state.isolatedWidth ?? 1.2 : null,
        isolatedHeight: type == FoundationType.isolated
            ? state.isolatedHeight ?? 0.4
            : null,
        clearIsolatedDimensions: type != FoundationType.isolated,
        pileCaps: type == FoundationType.pile && state.pileCaps.isEmpty
            ? const [PileCapSpec(length: 1.2, width: 1.2, height: 0.5)]
            : type == FoundationType.pile
                ? state.pileCaps
                : const [],
        columns: defaultColumn,
        showValidation: false,
      ),
    );
  }

  void selectStructureType(StructureType type) {
    emit(state.copyWith(structureType: type, showValidation: false));
  }

  void updateFoundationOptions({
    FoundationAlignment? alignment,
    int? mainBarDiameter,
    double? isolatedLength,
    double? isolatedWidth,
    double? isolatedHeight,
  }) {
    emit(
      state.copyWith(
        alignment: alignment,
        mainBarDiameter: mainBarDiameter,
        isolatedLength: isolatedLength,
        isolatedWidth: isolatedWidth,
        isolatedHeight: isolatedHeight,
        showValidation: false,
      ),
    );
  }

  void updateColumn(int index, ColumnSpec column) {
    final columns = [...state.columns]..[index] = column;
    emit(state.copyWith(columns: columns));
  }

  void addColumn() {
    emit(
      state.copyWith(
        columns: [
          ...state.columns,
          const ColumnSpec(
            width: 0.2,
            thickness: 0.2,
            quantity: 1,
            mainBarsCount: 4,
            mainBarDiameter: 16,
          ),
        ],
      ),
    );
  }

  void removeColumn(int index) {
    if (state.columns.length == 1) return;
    emit(state.copyWith(columns: [...state.columns]..removeAt(index)));
  }

  void updatePileCap(int index, PileCapSpec pileCap) {
    final caps = [...state.pileCaps]..[index] = pileCap;
    emit(state.copyWith(pileCaps: caps));
  }

  void addPileCap() {
    emit(
      state.copyWith(
        pileCaps: [
          ...state.pileCaps,
          const PileCapSpec(length: 1.2, width: 1.2, height: 0.5),
        ],
      ),
    );
  }

  void removePileCap(int index) {
    if (state.pileCaps.length == 1) return;
    emit(state.copyWith(pileCaps: [...state.pileCaps]..removeAt(index)));
  }

  void toggleMaterial(ProjectMaterial material) {
    final materials = [...state.materials];
    final index = materials.indexWhere(
      (item) => item.selectionKey == material.selectionKey,
    );
    index == -1 ? materials.add(material) : materials.removeAt(index);
    emit(state.copyWith(materials: materials, showValidation: false));
  }

  void updateDetails(ProjectDetails details) {
    emit(state.copyWith(details: details, showValidation: false));
  }

  bool next() {
    if (!state.isStepValid(state.currentStep)) {
      emit(state.copyWith(showValidation: true));
      return false;
    }
    if (state.currentStep < ProjectWizardState.stepCount - 1) {
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          showValidation: false,
        ),
      );
    }
    return true;
  }

  void back() {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          showValidation: false,
        ),
      );
    }
  }

  void goToCompletedStep(int step) {
    if (step <= state.currentStep ||
        List.generate(step, state.isStepValid).every((valid) => valid)) {
      emit(state.copyWith(currentStep: step, showValidation: false));
    }
  }

  ConstructionProject buildProject() {
    if (!state.canComplete) {
      throw StateError('The project draft is incomplete.');
    }
    final now = DateTime.now();
    return ConstructionProject(
      id: _initialProject?.id ?? '${now.microsecondsSinceEpoch}',
      name: state.name.trim(),
      location: state.location.trim(),
      provinceId: state.provinceId,
      provinceName: state.provinceName,
      districtId: state.districtId,
      districtName: state.districtName,
      imagePath: state.imagePath,
      createdAt: _initialProject?.createdAt ?? now,
      updatedAt: now,
      floors: state.floors,
      roof: state.roof,
      foundationStructure: FoundationStructureSpec(
        foundationType: state.foundationType!,
        structureType: state.structureType!,
        alignment: state.alignment,
        mainBarDiameter: state.mainBarDiameter,
        isolatedLength: state.isolatedLength,
        isolatedWidth: state.isolatedWidth,
        isolatedHeight: state.isolatedHeight,
        columns: state.columns,
        pileCaps: state.pileCaps,
      ),
      materials: state.materials,
      details: state.details,
    );
  }
}

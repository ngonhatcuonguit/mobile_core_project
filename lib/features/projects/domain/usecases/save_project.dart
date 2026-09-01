import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/repositories/project_repository.dart';

class SaveProject implements UseCase<void, ConstructionProject> {
  const SaveProject(this._repository);

  final ProjectRepository _repository;

  @override
  Future<void> call(ConstructionProject project) {
    return _repository.saveProject(project);
  }
}

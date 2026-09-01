import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/repositories/project_repository.dart';

class GetProjects implements UseCase<List<ConstructionProject>, NoParams> {
  const GetProjects(this._repository);

  final ProjectRepository _repository;

  @override
  Future<List<ConstructionProject>> call(NoParams params) {
    return _repository.getProjects();
  }
}

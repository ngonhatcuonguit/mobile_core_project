import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  const ProjectRepositoryImpl(this._store);

  final ProjectStore _store;

  @override
  Future<List<ConstructionProject>> getProjects() => _store.getAll();

  @override
  Future<void> saveProject(ConstructionProject project) => _store.save(project);

  @override
  Future<void> deleteProject(String id) => _store.delete(id);
}

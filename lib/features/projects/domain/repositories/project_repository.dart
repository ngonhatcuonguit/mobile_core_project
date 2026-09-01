import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

abstract class ProjectRepository {
  Future<List<ConstructionProject>> getProjects();

  Future<void> saveProject(ConstructionProject project);

  Future<void> deleteProject(String id);
}

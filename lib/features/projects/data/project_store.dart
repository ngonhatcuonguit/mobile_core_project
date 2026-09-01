import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

abstract class ProjectStore {
  Future<List<ConstructionProject>> getAll();

  Future<void> save(ConstructionProject project);

  Future<void> delete(String id);
}

class InMemoryProjectStore implements ProjectStore {
  final Map<String, ConstructionProject> _projects = {};

  @override
  Future<List<ConstructionProject>> getAll() async {
    final projects = _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<void> save(ConstructionProject project) async {
    _projects[project.id] = project;
  }

  @override
  Future<void> delete(String id) async {
    _projects.remove(id);
  }
}

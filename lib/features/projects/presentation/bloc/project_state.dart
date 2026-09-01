import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

enum ProjectStatus { initial, loading, success, failure, saving }

class ProjectState extends Equatable {
  const ProjectState({
    this.status = ProjectStatus.initial,
    this.projects = const [],
    this.errorMessage,
  });

  final ProjectStatus status;
  final List<ConstructionProject> projects;
  final String? errorMessage;

  ProjectState copyWith({
    ProjectStatus? status,
    List<ConstructionProject>? projects,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, projects, errorMessage];
}

import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/features/projects/data/project_database.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';

class ProjectStoreFactory {
  const ProjectStoreFactory._();

  static ProjectStore create() {
    if (kIsWeb ||
        !const {TargetPlatform.android, TargetPlatform.iOS}
            .contains(defaultTargetPlatform)) {
      return InMemoryProjectStore();
    }
    return ProjectDatabase.instance;
  }
}

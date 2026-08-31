import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_database.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';

class MaterialLibraryStoreFactory {
  MaterialLibraryStoreFactory._();

  static final MaterialLibraryStore _fallback = InMemoryMaterialLibraryStore();

  static MaterialLibraryStore create() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return MaterialLibraryDatabase.instance;
    }
    return _fallback;
  }
}

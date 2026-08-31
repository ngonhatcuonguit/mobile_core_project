import 'package:dio/dio.dart';
import 'package:flutter_core_project/core/network/api_client.dart';
import 'package:flutter_core_project/core/network/dio_factory.dart';
import 'package:flutter_core_project/core/storage/local_storage.dart';
import 'package:flutter_core_project/data/data_sources/local/notification_local_data_source.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_remote_data_source.dart';
import 'package:flutter_core_project/data/repositories/notification/notification_repository_impl.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';
import 'package:flutter_core_project/domain/usecases/register_device_token.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_repository_impl.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store_factory.dart';
import 'package:flutter_core_project/features/material_library/domain/repositories/material_library_repository.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/delete_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/get_material_library_items.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/save_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_cubit.dart';
import 'package:flutter_core_project/services/firebase_messaging_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  if (sl.isRegistered<LocalStorage>()) return;

  final preferences = await SharedPreferences.getInstance();
  sl.registerSingleton<LocalStorage>(
    SharedPreferencesLocalStorage(preferences),
  );

  sl.registerLazySingleton<Dio>(() => DioFactory(sl()).create());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton(() => RegisterDeviceToken(sl()));
  sl.registerLazySingleton(() => FirebaseMessagingService(sl()));

  sl.registerLazySingleton<MaterialLibraryStore>(
    MaterialLibraryStoreFactory.create,
  );
  sl.registerLazySingleton<MaterialLibraryRepository>(
    () => MaterialLibraryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMaterialLibraryItems(sl()));
  sl.registerLazySingleton(() => SaveMaterialLibraryItem(sl()));
  sl.registerLazySingleton(() => DeleteMaterialLibraryItem(sl()));
  sl.registerFactory(
    () => MaterialLibraryCubit(
      getItems: sl(),
      saveItem: sl(),
      deleteItem: sl(),
    ),
  );
}

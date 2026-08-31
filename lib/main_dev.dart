import 'package:flutter_core_project/bootstrap.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';

Future<void> main() => bootstrap(
      environment: AppEnvironment.dev,
      debugShowCheckedModeBanner: true,
    );

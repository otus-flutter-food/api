import 'dart:io';

import 'package:conduit_core/conduit_core.dart';
import 'package:foodapi/foodapi.dart';

Future main() async {
  final app = Application<FoodapiChannel>()
    ..options.configurationFilePath = "config.yaml"
    ..options.port = int.parse(Platform.environment['PORT'] ?? '8888')
    ..options.address = InternetAddress.anyIPv4;

  await app.startOnCurrentIsolate();

  print("Application started on 0.0.0.0:${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}

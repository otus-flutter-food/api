import 'package:foodapi/foodapi.dart';

Future main() async {
  final app = Application<FoodapiChannel>()
    ..options.configurationFilePath = "config.yaml"
    ..options.port = 8888;

  await app.start(
      numberOfInstances: 3, consoleLogging: true); // startOnCurrentIsolate();

  print("Application started on port: ${app.options.port}.");
  print("Use Ctrl-C (SIGINT) to stop running the application.");
}

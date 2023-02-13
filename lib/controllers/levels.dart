import 'dart:convert';

import 'package:foodapi/foodapi.dart';
import 'package:foodapi/utils/levels/levels_dto.dart';

class LevelController extends ResourceController {
  LevelController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getLevels() async {
    final level = await load();
    //String rawJson = jsonEncode(level);
    Response response = Response.ok(level);

    return response;
  }

  Future<dynamic> load() async {
    // print(File('classic.txt').exists());
    String ret;
    ret = await File('./assets/classic.txt').readAsString();
    final levels = await LevelDto.openLevels(ret);

    return Future.value(levels.values.take(30).map((v) => v.toJson()).toList());

    //print(contents);

    // File('classic.txt').readAsString().then((String contents) {
    //   print(contents);
    //   return contents;
    // });
    // File('.\classic.txt').readAsString().then((String contents) {
    //   print(contents);
    //   return contents;
    // });
    // File('./assets/classic.txt').readAsString().then((String contents) {
    //   print(contents);
    //   return contents;
    // });
    // File('.\assets\classic.txt').readAsString().then((String contents) {
    //   print(contents);
    //   return contents;
    // });
//     Directory dir = Directory('.');
// // execute an action on each entry
//     dir.list(recursive: false).forEach((f) {
//       print(f);
//     });
    // return "";
  }
}

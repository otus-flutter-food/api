import 'package:conduit/conduit.dart';

import '../model/freezer.dart';

class FreezerController extends ManagedObjectController<Freezer> {
  FreezerController(ManagedContext context) : super(context);
}

class FreezersController extends ResourceController {
  FreezersController(this.context);
  // {
  //   policy!.allowedOrigins.add("https://dart.nvavia.ru/recipe");
  //   policy!.allowedOrigins.add("localhost:8888/recipe");
  //   policy!.allowedMethods.add("GET");
  // }

  final ManagedContext context;

  @Operation.get()
  Future<Response> getFreezer() async {
    final query = Query<Freezer>(context)
      ..join(object: (f) => f.ingredient).join(object: (i) => i.measureUnit);

    final freezer = await query.fetch();
    Response response = Response.ok(freezer);
    // final aloowCORS = <String, dynamic>{"Access-Control-Allow-Origin": "*"};
    // response.headers.addEntries(aloowCORS.entries);
    // // response.addheaders.;
    // CORSPolicy.defaultPolicy.allowedOrigins.add("localhost:8888/recipe");
    return response;
  }
}

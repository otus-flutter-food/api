import 'package:conduit_core/conduit_core.dart';

class SimpleTestController extends ResourceController {
  @Operation.get()
  Future<Response> getTest() async {
    return Response.ok({'message': 'Hello World'});
  }
}
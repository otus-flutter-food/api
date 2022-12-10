import 'package:conduit/conduit.dart';
import 'package:conduit_common/conduit_common.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:uuid/uuid.dart';

import '../model/user.dart';

class UserInfoController extends ResourceController {

  UserInfoController(this.context);
  ManagedContext context;

  @Operation.get("id")
  Future<Response> getUser(@Bind.path("id") String id) async {
    final query = Query<User>(context)
      ..where((x) => x.id).equalTo(int.tryParse(id));
    final data = await query.fetchOne();
    return Response.ok(data);
  }
}

class UserController extends ResourceController {

  UserController(this.context);
  ManagedContext context;

  @override
  Map<String, APIResponse> documentOperationResponses(
      APIDocumentContext context, Operation operation) {
    if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("User is logged in", context.schema["Token"]),
        "403": APIResponse.schema(
          "User credentials are invalid",
          context.schema["Error"],
        ),
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("User is created", context.schema["Status"]),
        "409": APIResponse.schema(
            "User is already exists", context.schema["Error"])
      };
    } else
      return {};
  }

  @Operation.post()
  Future<Response> register(@Bind.body() User user) async {
    final query = Query<User>(context)
      ..where((x) => x.login).equalTo(user.login);
    final registered = await query.fetchOne();
    if (registered != null) {
      return Response.conflict(body: {"error": "login is already registered"});
    }
    final newUser = Query<User>(context)
      ..values.login = user.login
      ..values.password = user.password;
    await newUser.insert();
    return Response.ok({'status': 'ok'});
  }

  @Operation.put()
  Future<Response> auth(@Bind.body() User user) async {
    final query = Query<User>(context)
      ..where((x) => x.login).equalTo(user.login)
      ..where((x) => x.password).equalTo(user.password);
    final registered = await query.fetchOne();
    final token = const Uuid().v4.toString();
    query.values.token = token;
    await query.updateOne();

    if (registered == null) {
      return Response.forbidden(body: {'status': 'credentials are invalid'});
    } else {
      return Response.ok({'token': token});
    }
  }
}

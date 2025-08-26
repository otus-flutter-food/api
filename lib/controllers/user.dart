import 'package:conduit_common/conduit_common.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:uuid/uuid.dart';

import '../model/user.dart';
import '../middleware/naming_middleware.dart';

class UserInfoController extends NamingController {
  UserInfoController(this.context);

  ManagedContext context;
  

  @Operation.get("id")
  Future<Response> getUser(@Bind.path("id") String id) async {
    final query = Query<User>(context)
      ..where((x) => x.id).equalTo(int.tryParse(id));
    final data = await query.fetchOne();
    if (data == null) {
      return createResponseWithNamingConversion(404, {'error': 'User not found'});
    }
    return createResponseWithNamingConversion(200, data.asMap());
  }
}

class UserController extends NamingController {
  UserController(this.context);

  ManagedContext context;


  @Operation.post()
  Future<Response> register() async {
    try {
      // Декодируем с поддержкой camelCase конвертации
      final body = await decodeBodyWithNamingConversion();
      
      if (body['login'] == null || body['password'] == null) {
        return createResponseWithNamingConversion(400, {"error": "login and password are required"});
      }
      
      // Проверяем, не зарегистрирован ли уже пользователь
      final query = Query<User>(context)
        ..where((x) => x.login).equalTo(body['login']);
      final registered = await query.fetchOne();
      
      if (registered != null) {
        return createResponseWithNamingConversion(409, {"error": "login is already registered"});
      }
      
      // Создаем нового пользователя
      final newUser = User()
        ..login = body['login']
        ..password = body['password']
        ..firstName = body['first_name']
        ..lastName = body['last_name']
        ..phone = body['phone']
        ..avatarUrl = body['avatar_url']
        ..birthday = body['birthday'] != null ? DateTime.tryParse(body['birthday']) : null;
        
      final insertQuery = Query<User>(context)
        ..values = newUser;
        
      final insertedUser = await insertQuery.insert();
      insertedUser.password = null; // Don't return password
      
      return createResponseWithNamingConversion(200, {"status": "ok", "user": insertedUser.asMap()});
    } catch (e) {
      print("Error registering user: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }

  @Operation.put()
  Future<Response> auth() async {
    try {
      // Декодируем с поддержкой camelCase конвертации
      final body = await decodeBodyWithNamingConversion();
      
      if (body['login'] == null || body['password'] == null) {
        return createResponseWithNamingConversion(400, {"error": "login and password are required"});
      }
      
      final query = Query<User>(context)
        ..where((x) => x.login).equalTo(body['login'])
        ..where((x) => x.password).equalTo(body['password']);
      final registered = await query.fetchOne();

      if (registered == null) {
        return createResponseWithNamingConversion(403, {'error': 'credentials are invalid'});
      }
      
      final token = const Uuid().v4();
      final updateQuery = Query<User>(context)
        ..where((x) => x.id).equalTo(registered.id!)
        ..values.token = token;
      await updateQuery.updateOne();
      
      return createResponseWithNamingConversion(200, {'token': token});
    } catch (e) {
      print("Error authenticating user: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }
}

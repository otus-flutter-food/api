import 'package:conduit_common/conduit_common.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:uuid/uuid.dart';

import '../model/user.dart';
import '../middleware/naming_middleware.dart';

class UserInfoController extends NamingController {
  UserInfoController(this.context);

  ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(context, operation) {
    return {
      '200': APIResponse.schema('Публичный пользователь', context.schema['UserPublic']),
      '404': APIResponse('User not found'),
      '400': APIResponse('Invalid id'),
    };
  }

  @Operation.get("id")
  Future<Response> getUser(@Bind.path("id") String id) async {
    try {
      final userId = int.tryParse(id);
      if (userId == null) {
        return createResponseWithNamingConversion(400, {'error': 'Invalid id'});
      }
      final store = context.persistentStore as PostgreSQLPersistentStore;
      // Discover available columns in production schema
      final colsRes = await store.execute(
        "SELECT column_name FROM information_schema.columns WHERE table_name = '_user'"
      ) as List<List<dynamic>>;
      final cols = colsRes.map((r) => r.first as String).toSet();

      // Build safe SELECT with only existing columns
      final wanted = <String, String>{
        'id': 'id',
        if (cols.contains('login')) 'login': 'login',
        if (cols.contains('first_name')) 'first_name': 'first_name',
        if (cols.contains('last_name')) 'last_name': 'last_name',
        if (cols.contains('avatar_url')) 'avatar_url': 'avatar_url',
        if (cols.contains('phone')) 'phone': 'phone',
        if (cols.contains('birthday')) 'birthday': 'birthday',
      };
      final selectList = wanted.keys.join(', ');
      final rows = await store.execute(
        'SELECT ' + selectList + ' FROM _user WHERE id=@id LIMIT 1',
        substitutionValues: {'id': userId},
      ) as List<List<dynamic>>;
      if (rows.isEmpty) {
        return createResponseWithNamingConversion(404, {'error': 'User not found'});
      }
      final r = rows.first;
      final map = <String, dynamic>{};
      var i = 0;
      for (final k in wanted.keys) {
        map[k] = r[i++];
      }
      // Convert to API naming (camelCase)
      final out = <String, dynamic>{
        'id': map['id'],
        if (map.containsKey('login')) 'login': map['login'],
        if (map.containsKey('first_name')) 'firstName': map['first_name'],
        if (map.containsKey('last_name')) 'lastName': map['last_name'],
        if (map.containsKey('avatar_url')) 'avatarUrl': map['avatar_url'],
        if (map.containsKey('phone')) 'phone': map['phone'],
        if (map.containsKey('birthday')) 'birthday': (map['birthday'] as DateTime?)?.toIso8601String(),
      };
      return createResponseWithNamingConversion(200, out);
    } catch (e) {
      return createResponseWithNamingConversion(500, {'error': e.toString()});
    }
  }
}

class UserController extends NamingController {
  UserController(this.context);

  ManagedContext context;

  @override
  Map<String, APIResponse> documentOperationResponses(context, operation) {
    if (operation.method == 'POST') {
      return {
        '200': APIResponse.schema('Успешная регистрация', context.schema['RegistrationResponse']),
        '400': APIResponse('login and password are required'),
        '409': APIResponse('login is already registered'),
      };
    } else if (operation.method == 'PUT') {
      return {
        '200': APIResponse.schema('Токен авторизации', context.schema['AuthToken']),
        '400': APIResponse('login and password are required'),
        '403': APIResponse('credentials are invalid'),
      };
    }
    return {};
  }

  @Operation.post()
  Future<Response> register() async {
    try {
      // Декодируем с поддержкой camelCase конвертации
      final body = await decodeBodyWithNamingConversion();
      final login = body['login']?.toString();
      final password = body['password']?.toString();
      if (login == null || password == null) {
        return createResponseWithNamingConversion(400, {"error": "login and password are required"});
      }
      final store = context.persistentStore as PostgreSQLPersistentStore;
      // Проверка дубликата
      final dup = await store.execute('SELECT 1 FROM _user WHERE login=@login LIMIT 1', substitutionValues: {'login': login});
      if (dup.isNotEmpty) {
        return createResponseWithNamingConversion(409, {"error": "login is already registered"});
      }
      // Вставка (храним только обязательные поля для совместимости со схемой)
      final rows = await store.execute(
        'INSERT INTO _user (login, password) VALUES (@login, @password) RETURNING id, login',
        substitutionValues: {'login': login, 'password': password},
      ) as List<List<dynamic>>;
      final r = rows.first;
      return createResponseWithNamingConversion(200, {"status": "ok", "user": {"id": r[0], "login": r[1]}});
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
      final login = body['login']?.toString();
      final password = body['password']?.toString();
      if (login == null || password == null) {
        return createResponseWithNamingConversion(400, {"error": "login and password are required"});
      }
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final rows = await store.execute(
        'SELECT id FROM _user WHERE login=@login AND password=@password LIMIT 1',
        substitutionValues: {'login': login, 'password': password},
      ) as List<List<dynamic>>;
      if (rows.isEmpty) {
        return createResponseWithNamingConversion(403, {'error': 'credentials are invalid'});
      }
      final userId = rows.first.first as int;
      final token = const Uuid().v4();
      await store.execute('UPDATE _user SET token=@token WHERE id=@id', substitutionValues: {'token': token, 'id': userId});
      return createResponseWithNamingConversion(200, {'token': token});
    } catch (e) {
      print("Error authenticating user: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }
}

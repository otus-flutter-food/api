import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import '../model/freezer.dart';
import '../model/user.dart';
import '../model/ingredient.dart';

class FreezerController extends ResourceController {
  FreezerController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список продуктов в морозилке", APISchemaObject.array(ofSchema: context.schema['Freezer'])),
        "404": APIResponse("Продукт не найден в морозилке")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Продукт добавлен в морозилку", context.schema['Freezer']),
        "400": APIResponse("Ошибка валидации (неверный user ID или ingredient ID)")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Продукт в морозилке обновлён", context.schema['Freezer']),
        "404": APIResponse("Продукт не найден в морозилке"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Продукт удалён из морозилки"),
        "404": APIResponse("Продукт не найден в морозилке")
      };
    }
    return {};
  }
  
  @Operation.get()
  Future<Response> getAllFreezerItems() async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, f.count, u.id as user_id, i.id as ingredient_id, i.name '
      'FROM _freezer f '
      'JOIN _user u ON u.id = f.user_id '
      'JOIN _ingredient i ON i.id = f.ingredient_id') as List<List<dynamic>>;
    final results = rows.map((r) => {
      'id': r[0],
      'count': (r[1] as num?)?.toDouble(),
      'user': {'id': r[2]},
      'ingredient': {'id': r[3], 'name': r[4]},
    }).toList();
    return Response.ok(results);
  }
  
  @Operation.get('id')
  Future<Response> getFreezerItemByID(@Bind.path('id') int id) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, f.count, u.id as user_id, i.id as ingredient_id, i.name '
      'FROM _freezer f JOIN _user u ON u.id=f.user_id JOIN _ingredient i ON i.id=f.ingredient_id '
      'WHERE f.id=@id', substitutionValues: {'id': id}) as List<List<dynamic>>;
    if (rows.isEmpty) {
      return Response.notFound(body: {'error': 'Freezer item not found'});
    }
    final r = rows.first;
    return Response.ok({
      'id': r[0], 'count': (r[1] as num?)?.toDouble(),
      'user': {'id': r[2]}, 'ingredient': {'id': r[3], 'name': r[4]},
    });
  }
  
  @Operation.post()
  Future<Response> createFreezerItem() async {
    final Map<String, dynamic> body = await request!.body.decode();
    final userId = int.tryParse((body['userId'] ?? body['user']?['id'])?.toString() ?? '');
    final ingredientId = int.tryParse((body['ingredientId'] ?? body['ingredient']?['id'])?.toString() ?? '');
    final num? countNum = () { final c = body['count']; if (c is num) return c; if (c is String) return num.tryParse(c); return null; }();
    if (userId == null || ingredientId == null || countNum == null) {
      return Response.badRequest(body: {'error': 'userId/user.id, ingredientId/ingredient.id and count are required'});
    }
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final u = await store.execute('SELECT 1 FROM _user WHERE id=@id LIMIT 1', substitutionValues: {'id': userId});
    if (u.isEmpty) return Response.badRequest(body: {'error': 'Invalid user ID'});
    final i = await store.execute('SELECT 1 FROM _ingredient WHERE id=@id LIMIT 1', substitutionValues: {'id': ingredientId});
    if (i.isEmpty) return Response.badRequest(body: {'error': 'Invalid ingredient ID'});
    // If exists, update count
    final exists = await store.execute('SELECT id, count FROM _freezer WHERE user_id=@uid AND ingredient_id=@iid LIMIT 1', substitutionValues: {'uid': userId, 'iid': ingredientId}) as List<List<dynamic>>;
    if (exists.isNotEmpty) {
      final id = exists.first[0] as int;
      final current = (exists.first[1] as num?)?.toDouble() ?? 0.0;
      final newCount = current + countNum.toDouble();
      await store.execute('UPDATE _freezer SET count=CAST(@cnt AS float8) WHERE id=@id', substitutionValues: {'cnt': newCount, 'id': id});
      return await getFreezerItemByID(id);
    }
    final rows = await store.execute(
      'INSERT INTO _freezer (user_id, ingredient_id, count) VALUES ('
      'CAST(@uid AS int4), CAST(@iid AS int4), CAST(@cnt AS float8)) RETURNING id',
      substitutionValues: {'uid': userId, 'iid': ingredientId, 'cnt': countNum},
    ) as List<List<dynamic>>;
    final id = rows.first.first as int;
    return await getFreezerItemByID(id);
  }
  
  @Operation.put('id')
  Future<Response> updateFreezerItem(
    @Bind.path('id') int id,
  ) async {
    final Map<String, dynamic> body = await request!.body.decode();
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};
    if (body.containsKey('count')) {
      final c = body['count']; final parsed = c is num ? c.toDouble() : (c is String ? double.tryParse(c) : null);
      if (parsed != null) { updates.add('count = CAST(@cnt AS float8)'); values['cnt'] = parsed; }
    }
    final uid = int.tryParse((body['userId'] ?? body['user']?['id'])?.toString() ?? '');
    if (uid != null) { updates.add('user_id = CAST(@uid AS int4)'); values['uid'] = uid; }
    final iid = int.tryParse((body['ingredientId'] ?? body['ingredient']?['id'])?.toString() ?? '');
    if (iid != null) { updates.add('ingredient_id = CAST(@iid AS int4)'); values['iid'] = iid; }
    if (updates.isEmpty) return Response.badRequest(body: {'error': 'No fields to update'});
    final store = context.persistentStore as PostgreSQLPersistentStore;
    await store.execute('UPDATE _freezer SET ${updates.join(', ')} WHERE id=@id', substitutionValues: values);
    return await getFreezerItemByID(id);
  }
  
  @Operation.delete('id')
  Future<Response> deleteFreezerItem(@Bind.path('id') int id) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    await store.execute('DELETE FROM _freezer WHERE id=@id', substitutionValues: {'id': id});
    final check = await store.execute('SELECT 1 FROM _freezer WHERE id=@id', substitutionValues: {'id': id});
    if (check.isNotEmpty) {
      return Response.notFound(body: {'error': 'Freezer item not found'});
    }
    return Response.ok({'message': 'Freezer item deleted successfully', 'id': id});
  }
  
  // Additional endpoints for user-specific freezer
  @Operation.get('user', 'userId')
  Future<Response> getUserFreezer(@Bind.path('userId') int userId) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, f.count, i.id, i.name '
      'FROM _freezer f JOIN _ingredient i ON i.id=f.ingredient_id '
      'WHERE f.user_id=@uid', substitutionValues: {'uid': userId}) as List<List<dynamic>>;
    final data = rows.map((r) => {'id': r[0], 'count': (r[1] as num?)?.toDouble(), 'ingredient': {'id': r[2], 'name': r[3]}}).toList();
    return Response.ok(data);
  }
}

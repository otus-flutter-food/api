import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeStepController extends ResourceController {
  RecipeStepController(this.context);

  final ManagedContext context;

  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список шагов рецептов", APISchemaObject.array(ofSchema: context.schema['RecipeStep'])),
        "404": APIResponse("Шаг не найден")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Шаг создан", context.schema['RecipeStep']),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Шаг обновлён", context.schema['RecipeStep']),
        "404": APIResponse("Шаг не найден"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Шаг успешно удалён"),
        "404": APIResponse("Шаг не найден"),
        "400": APIResponse("Нельзя удалить шаг, связанный с рецептами")
      };
    }
    return {};
  }

  @Operation.get()
  Future<Response> getAllSteps({
    @Bind.query('name') String? name,
  }) async {
    final query = Query<RecipeStep>(context)
      ..join(set: (s) => s.recipeStepLinks);
    
    // Добавляем поиск по имени если параметр передан
    if (name != null && name.isNotEmpty) {
      query.where((s) => s.name).contains(name, caseSensitive: false);
    }
    
    final steps = await query.fetch();
    return Response.ok(steps);
  }

  @Operation.get('id')
  Future<Response> getStepById(@Bind.path('id') int id) async {
    final query = Query<RecipeStep>(context)
      ..where((s) => s.id).equalTo(id)
      ..join(set: (s) => s.recipeStepLinks);
    
    final step = await query.fetchOne();
    
    if (step == null) {
      return Response.notFound(body: {'error': 'Step not found'});
    }
    
    return Response.ok(step);
  }

  @Operation.post()
  Future<Response> createStep() async {
    final Map<String, dynamic> body = await request!.body.decode();
    final name = body['name']?.toString();
    final duration = () {
      final d = body['duration'];
      if (d is num) return d.toInt();
      if (d is String) return int.tryParse(d);
      return null;
    }();
    if (name == null || duration == null) {
      return Response.badRequest(body: {'error': 'name and duration are required'});
    }
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final rows = await store.execute(
        'INSERT INTO _recipestep (name, duration) VALUES (@name, CAST(@duration AS int4)) RETURNING id, name, duration',
        substitutionValues: {'name': name, 'duration': duration},
      ) as List<List<dynamic>>;
      if (rows.isEmpty) return Response.serverError(body: {'error': 'Insert failed'});
      final r = rows.first;
      return Response.ok({'id': r[0], 'name': r[1], 'duration': r[2]});
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.put('id')
  Future<Response> updateStep(
    @Bind.path('id') int id,
  ) async {
    final Map<String, dynamic> body = await request!.body.decode();
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};
    if (body.containsKey('name')) {
      updates.add('name = @name');
      values['name'] = body['name'].toString();
    }
    if (body.containsKey('duration')) {
      final d = body['duration'];
      final parsed = d is num ? d.toInt() : (d is String ? int.tryParse(d) : null);
      if (parsed != null) {
        updates.add('duration = CAST(@duration AS int4)');
        values['duration'] = parsed;
      }
    }
    if (updates.isEmpty) {
      return Response.badRequest(body: {'error': 'No fields to update'});
    }
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      await store.execute(
        'UPDATE _recipestep SET ${updates.join(', ')} WHERE id = @id',
        substitutionValues: values,
      );
      final res = await store.execute(
        'SELECT id, name, duration FROM _recipestep WHERE id = @id',
        substitutionValues: {'id': id},
      ) as List<List<dynamic>>;
      if (res.isEmpty) return Response.notFound(body: {'error': 'Step not found'});
      final r = res.first;
      return Response.ok({'id': r[0], 'name': r[1], 'duration': r[2]});
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.delete('id')
  Future<Response> deleteStep(@Bind.path('id') int id) async {
    final checkQuery = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.step!.id).equalTo(id);
    
    final linksCount = await checkQuery.reduce.count();
    
    if (linksCount > 0) {
      return Response.badRequest(
        body: {'error': 'Cannot delete step that is linked to recipes. Remove links first.'},
      );
    }
    
    final query = Query<RecipeStep>(context)
      ..where((s) => s.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Step not found'});
    }
    
    return Response.ok({'message': 'Step deleted successfully'});
  }

}

import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeStepLinkController extends ResourceController {
  RecipeStepLinkController(this.context);

  final ManagedContext context;

  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список связей шагов с рецептами", APISchemaObject.array(ofSchema: context.schema['RecipeStepLink'])),
        "404": APIResponse("Связь не найдена")
      };
    } else if (operation.method == "POST") {
      // Для batch операций возвращаем массив
      if (request?.path.segments.last == "batch") {
        return {
          "200": APIResponse.schema("Связи созданы", APISchemaObject.array(ofSchema: context.schema['RecipeStepLink'])),
          "400": APIResponse("Ошибка валидации данных")
        };
      }
      return {
        "200": APIResponse.schema("Связь создана", context.schema['RecipeStepLink']),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Связь обновлена", context.schema['RecipeStepLink']),
        "404": APIResponse("Связь не найдена"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Связь успешно удалена"),
        "404": APIResponse("Связь не найдена")
      };
    }
    return {};
  }
  
  @override
  APIRequestBody? documentOperationRequestBody(context, Operation? operation) {
    if (operation?.method == "POST") {
      // Batch операция принимает массив
      if (operation?.pathVariables?.contains("batch") ?? false) {
        return APIRequestBody.schema(
          APISchemaObject.array(
            ofSchema: APISchemaObject.object({
              "recipe": APISchemaObject.object({"id": APISchemaObject.integer()}),
              "step": APISchemaObject.object({"id": APISchemaObject.integer()}),
              "number": APISchemaObject.integer(),
            })
          ),
          description: "Массив связей для создания",
        );
      }
      // Обычный POST
      return APIRequestBody.schema(
        APISchemaObject.object({
          "recipe": APISchemaObject.object({"id": APISchemaObject.integer()}),
          "step": APISchemaObject.object({"id": APISchemaObject.integer()}),
          "number": APISchemaObject.integer(),
        }),
        description: "Данные связи",
      );
    } else if (operation?.method == "PUT") {
      // Для reorderSteps
      if (operation?.pathVariables?.isEmpty ?? true) {
        return APIRequestBody.schema(
          APISchemaObject.object({
            "recipeId": APISchemaObject.integer(),
            "stepOrders": APISchemaObject.array(
              ofSchema: APISchemaObject.object({
                "linkId": APISchemaObject.integer(),
                "number": APISchemaObject.integer(),
              })
            ),
          }),
          description: "Данные для переупорядочивания шагов",
        );
      }
      // Обычный PUT для обновления
      return APIRequestBody.schema(
        APISchemaObject.object({
          "number": APISchemaObject.integer(),
        }),
        description: "Обновленные данные связи",
      );
    }
    return null;
  }

  @Operation.get()
  Future<Response> getAllRecipeStepLinks(
    @Bind.query('recipeId') int? recipeId,
    @Bind.query('stepId') int? stepId,
  ) async {
    final query = Query<RecipeStepLink>(context)
      ..join(object: (rsl) => rsl.recipe)
      ..join(object: (rsl) => rsl.step);
    
    if (recipeId != null) {
      query.where((rsl) => rsl.recipe!.id).equalTo(recipeId);
    }
    
    if (stepId != null) {
      query.where((rsl) => rsl.step!.id).equalTo(stepId);
    }
    
    query.sortBy((rsl) => rsl.number, QuerySortOrder.ascending);
    
    final links = await query.fetch();
    return Response.ok(links);
  }

  @Operation.get('id')
  Future<Response> getRecipeStepLinkById(@Bind.path('id') int id) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.id).equalTo(id)
      ..join(object: (rsl) => rsl.recipe)
      ..join(object: (rsl) => rsl.step);
    
    final link = await query.fetchOne();
    
    if (link == null) {
      return Response.notFound(body: {'error': 'RecipeStepLink not found'});
    }
    
    return Response.ok(link);
  }

  @Operation.post()
  Future<Response> createRecipeStepLink() async {
    final Map<String, dynamic> body = await request!.body.decode();
    final recipeId = int.tryParse(
        (body['recipeId'] ?? body['recipe']?['id'])?.toString() ?? '');
    final stepId = int.tryParse(
        (body['stepId'] ?? body['step']?['id'])?.toString() ?? '');
    final number = () {
      final n = body['number'];
      if (n == null) return null;
      if (n is num) return n.toInt();
      if (n is String) return int.tryParse(n);
      return null;
    }();

    if (recipeId == null || stepId == null) {
      return Response.badRequest(
          body: {'error': 'recipeId/recipe.id and stepId/step.id are required'});
    }

    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{
        'recipe_id': recipeId,
        'step_id': stepId,
        'number': number ?? 0,
      };
      final insertSql = 'INSERT INTO _recipesteplink (recipe_id, step_id, number) '
          'VALUES (CAST(@recipe_id AS int4), CAST(@step_id AS int4), CAST(@number AS int4)) '
          'RETURNING id';
      final rows = await store.execute(insertSql, substitutionValues: values)
          as List<List<dynamic>>;
      if (rows.isEmpty) {
        return Response.serverError(body: {'error': 'Insert failed'});
      }
      final newId = rows.first.first as int;
      return await _selectLinkById(newId);
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.put('id')
  Future<Response> updateRecipeStepLink(
    @Bind.path('id') int id,
  ) async {
    final Map<String, dynamic> body = await request!.body.decode();
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};
    if (body.containsKey('number')) {
      final n = body['number'];
      final parsed = n is num ? n.toInt() : (n is String ? int.tryParse(n) : null);
      if (parsed != null) {
        updates.add('number = CAST(@number AS int4)');
        values['number'] = parsed;
      }
    }
    final rId = int.tryParse((body['recipeId'] ?? body['recipe']?['id'])?.toString() ?? '');
    if (rId != null) {
      updates.add('recipe_id = CAST(@recipe_id AS int4)');
      values['recipe_id'] = rId;
    }
    final sId = int.tryParse((body['stepId'] ?? body['step']?['id'])?.toString() ?? '');
    if (sId != null) {
      updates.add('step_id = CAST(@step_id AS int4)');
      values['step_id'] = sId;
    }
    if (updates.isEmpty) {
      return Response.badRequest(body: {'error': 'No fields to update'});
    }
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final updated = await store.execute(
          'UPDATE _recipesteplink SET ${updates.join(', ')} WHERE id = @id',
          substitutionValues: values);
      if (updated.isEmpty) {
        // UPDATE returns empty list; confirm existence
      }
      return await _selectLinkById(id);
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.delete('id')
  Future<Response> deleteRecipeStepLink(@Bind.path('id') int id) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'RecipeStepLink not found'});
    }
    
    return Response.ok({'message': 'RecipeStepLink deleted successfully'});
  }

  @Operation.get('recipeId')
  Future<Response> getStepsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.recipe!.id).equalTo(recipeId)
      ..join(object: (rsl) => rsl.step)
      ..sortBy((rsl) => rsl.number, QuerySortOrder.ascending);
    
    final links = await query.fetch();
    return Response.ok(links);
  }

  @Operation.post('batch')
  Future<Response> batchCreateRecipeStepLinks(@Bind.body() List<Map<String, dynamic>> links) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final ids = <int>[];
      for (final link in links) {
        final recipeId = int.tryParse((link['recipeId'] ?? link['recipe']?['id'])?.toString() ?? '');
        final stepId = int.tryParse((link['stepId'] ?? link['step']?['id'])?.toString() ?? '');
        final number = () {
          final n = link['number'];
          if (n is num) return n.toInt();
          if (n is String) return int.tryParse(n);
          return 0;
        }();
        if (recipeId == null || stepId == null) {
          return Response.badRequest(body: {'error': 'recipeId/stepId required'});
        }
        final rows = await store.execute(
          'INSERT INTO _recipesteplink (recipe_id, step_id, number) '
          'VALUES (CAST(@recipe_id AS int4), CAST(@step_id AS int4), CAST(@number AS int4)) RETURNING id',
          substitutionValues: {
            'recipe_id': recipeId,
            'step_id': stepId,
            'number': number,
          },
        ) as List<List<dynamic>>;
        if (rows.isNotEmpty) ids.add(rows.first.first as int);
      }
      final results = <Map<String, dynamic>>[];
      for (final id in ids) {
        final res = await _selectLinkById(id);
        if (res.statusCode == 200) {
          results.add((res.body as Map).cast<String, dynamic>());
        }
      }
      return Response.ok(results);
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.put()
  Future<Response> reorderSteps(@Bind.body() Map<String, dynamic> body) async {
    final recipeId = body['recipeId'] as int?;
    final stepOrders = body['stepOrders'] as List<dynamic>?;
    
    if (recipeId == null || stepOrders == null) {
      return Response.badRequest(
        body: {'error': 'recipeId and stepOrders are required'},
      );
    }
    
    final store = context.persistentStore as PostgreSQLPersistentStore;
    for (final order in stepOrders) {
      final linkId = int.tryParse(order['linkId'].toString());
      final newNumber = int.tryParse(order['number'].toString());
      if (linkId == null || newNumber == null) {
        return Response.badRequest(body: {'error': 'Invalid linkId/number'});
      }
      await store.execute(
        'UPDATE _recipesteplink SET number = CAST(@number AS int4) WHERE id = @id AND recipe_id = @recipe_id',
        substitutionValues: {
          'number': newNumber,
          'id': linkId,
          'recipe_id': recipeId,
        },
      );
    }
    
    return Response.ok({'message': 'Steps reordered successfully'});
  }

  Future<Response> _selectLinkById(int id) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final rows = await store.execute(
        'SELECT rsl.id, rsl.number, '
        'r.id, r.name, s.id, s.name '
        'FROM _recipesteplink rsl '
        'JOIN _recipe r ON r.id = rsl.recipe_id '
        'JOIN _recipestep s ON s.id = rsl.step_id '
        'WHERE rsl.id = @id',
        substitutionValues: {'id': id},
      ) as List<List<dynamic>>;
      if (rows.isEmpty) return Response.notFound();
      final row = rows.first;
      return Response.ok({
        'id': row[0],
        'number': row[1],
        'recipe': {'id': row[2], 'name': row[3]},
        'step': {'id': row[4], 'name': row[5]},
      });
    } catch (e) {
      return Response.serverError(body: {'error': e.toString()});
    }
  }

  @Operation.delete('recipeId')
  Future<Response> deleteAllStepsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    return Response.ok({'message': 'Deleted $deletedCount steps for recipe'});
  }
}

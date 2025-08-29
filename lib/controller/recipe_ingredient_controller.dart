import 'package:foodapi/foodapi.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:foodapi/model/ingredient.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeIngredientController extends ResourceController {
  RecipeIngredientController(this.context);

  final ManagedContext context;

  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список ингредиентов рецептов", APISchemaObject.array(ofSchema: context.schema['RecipeIngredient'])),
        "404": APIResponse("Ингредиент рецепта не найден")
      };
    } else if (operation.method == "POST") {
      // Для batch операций возвращаем массив
      if (request?.path.segments.last == "batch") {
        return {
          "200": APIResponse.schema("Ингредиенты рецепта созданы", APISchemaObject.array(ofSchema: context.schema['RecipeIngredient'])),
          "400": APIResponse("Ошибка валидации данных")
        };
      }
      return {
        "200": APIResponse.schema("Ингредиент рецепта создан", context.schema['RecipeIngredient']),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Ингредиент рецепта обновлён", context.schema['RecipeIngredient']),
        "404": APIResponse("Ингредиент рецепта не найден"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Ингредиент рецепта успешно удалён"),
        "404": APIResponse("Ингредиент рецепта не найден")
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
              "ingredient": APISchemaObject.object({"id": APISchemaObject.integer()}),
              "count": APISchemaObject.number(),
            })
          ),
          description: "Массив ингредиентов для создания",
        );
      }
      // Обычный POST
      return APIRequestBody.schema(
        APISchemaObject.object({
          "recipe": APISchemaObject.object({"id": APISchemaObject.integer()}),
          "ingredient": APISchemaObject.object({"id": APISchemaObject.integer()}),
          "count": APISchemaObject.number(),
        }),
        description: "Данные ингредиента рецепта",
      );
    } else if (operation?.method == "PUT") {
      // Обычный PUT для обновления
      return APIRequestBody.schema(
        APISchemaObject.object({
          "count": APISchemaObject.number(),
          "ingredient": APISchemaObject.object({"id": APISchemaObject.integer()})..isNullable = true,
        }),
        description: "Обновленные данные ингредиента",
      );
    }
    return null;
  }

  @Operation.get()
  Future<Response> getAllRecipeIngredients() async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final where = <String>[];
    final values = <String, dynamic>{};
    final qp = request!.raw.uri.queryParameters;
    final recipeId = int.tryParse(qp['recipeId'] ?? '');
    final ingredientId = int.tryParse(qp['ingredientId'] ?? '');
    if (recipeId != null) { where.add('ri.recipe_id = @rid'); values['rid'] = recipeId; }
    if (ingredientId != null) { where.add('ri.ingredient_id = @iid'); values['iid'] = ingredientId; }
    final rows = await store.execute(
      'SELECT ri.id, ri.count, i.id, i.name, r.id, r.name '
      'FROM _recipeingredient ri '
      'JOIN _ingredient i ON i.id = ri.ingredient_id '
      'JOIN _recipe r ON r.id = ri.recipe_id '
      '${where.isNotEmpty ? 'WHERE ' + where.join(' AND ') : ''} '
      'ORDER BY ri.id',
      substitutionValues: values,
    ) as List<List<dynamic>>;
    final list = rows.map((row) => {
      'id': row[0],
      'count': row[1],
      'ingredient': {'id': row[2], 'name': row[3]},
      'recipe': {'id': row[4], 'name': row[5]},
    }).toList();
    return Response.ok(list);
  }

  @Operation.get('id')
  Future<Response> getRecipeIngredientById(@Bind.path('id') int id) async {
    final query = Query<RecipeIngredient>(context)
      ..where((ri) => ri.id).equalTo(id)
      ..join(object: (ri) => ri.ingredient)
      ..join(object: (ri) => ri.recipe);
    
    final recipeIngredient = await query.fetchOne();
    
    if (recipeIngredient == null) {
      return Response.notFound(body: {'error': 'RecipeIngredient not found'});
    }
    
    return Response.ok(recipeIngredient);
  }

  @Operation.post()
  Future<Response> createRecipeIngredient() async {
    // Читаем JSON body вручную для поддержки вложенных объектов
    final Map<String, dynamic> body = await request!.body.decode();
    
    // Извлекаем ID из вложенных объектов
    final recipeId = (body['recipe']?['id'] as num?)?.toInt();
    final ingredientId = (body['ingredient']?['id'] as num?)?.toInt();
    final dynamic rawCount = body['count'];
    final num? count = rawCount is num ? rawCount : (rawCount is String ? num.tryParse(rawCount) : null);
    
    print('DEBUG RecipeIngredient: recipeId=$recipeId, ingredientId=$ingredientId, count=$count (${count.runtimeType})');
    
    if (recipeId == null || ingredientId == null || count == null) {
      return Response.badRequest(
        body: {'error': 'recipe.id, ingredient.id and count are required'}
      );
    }
    
    // Из-за несовместимости типов в ORM используем прямой SQL с явными кастами
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{
        'count': count,
        'ingredient_id': ingredientId,
        'recipe_id': recipeId,
      };

      // Кастуем к real для поддержки дробных значений
      final insertSql =
          'INSERT INTO _recipeingredient (count, ingredient_id, recipe_id) '
          'VALUES (CAST(@count AS real), CAST(@ingredient_id AS int4), CAST(@recipe_id AS int4)) '
          'RETURNING id';
      final inserted = await store.execute(insertSql, substitutionValues: values) as List<List<dynamic>>;
      if (inserted.isEmpty) {
        return Response.serverError(body: {'error': 'Failed to insert recipe ingredient'});
      }
      final newId = inserted.first.first as int;

      // Загружаем полные данные с join'ами
      final selectSql =
          'SELECT ri.id, ri.count, i.id, i.name, r.id, r.name '
          'FROM _recipeingredient ri '
          'JOIN _ingredient i ON i.id = ri.ingredient_id '
          'JOIN _recipe r ON r.id = ri.recipe_id '
          'WHERE ri.id = @id';
      final rows = await store.execute(selectSql, substitutionValues: {'id': newId}) as List<List<dynamic>>;
      if (rows.isEmpty) {
        return Response.serverError(body: {'error': 'Inserted recipe ingredient not found'});
      }
      final row = rows.first;
      return Response.ok({
        'id': row[0],
        'count': row[1],
        'ingredient': {'id': row[2], 'name': row[3]},
        'recipe': {'id': row[4], 'name': row[5]},
      });
    } catch (e) {
      print('DEBUG: RecipeIngredient creation error: $e');
      return Response.badRequest(body: {'error': 'Invalid recipe or ingredient ID: $e'});
    }
  }

  @Operation.put('id')
  Future<Response> updateRecipeIngredient(@Bind.path('id') int id) async {
    // Читаем JSON body вручную для поддержки вложенных объектов
    final Map<String, dynamic> body = await request!.body.decode();

    // Проверяем существование
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final exists = await store.execute('SELECT id FROM _recipeingredient WHERE id=@id', substitutionValues: {'id': id}) as List<List<dynamic>>;
    if (exists.isEmpty) return Response.notFound(body: {'error': 'RecipeIngredient not found'});

    // Формируем SET
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};

    if (body.containsKey('count')) {
      final dynamic raw = body['count'];
      final num? parsed = raw is num ? raw : (raw is String ? num.tryParse(raw) : null);
      if (parsed != null) {
        updates.add('count = CAST(@count AS real)');
        values['count'] = parsed;
      }
    }
    if (body.containsKey('recipe') && body['recipe'] is Map && body['recipe']['id'] != null) {
      final rid = int.tryParse(body['recipe']['id'].toString());
      if (rid != null) {
        updates.add('recipe_id = CAST(@recipe_id AS int4)');
        values['recipe_id'] = rid;
      }
    }
    if (body.containsKey('ingredient') && body['ingredient'] is Map && body['ingredient']['id'] != null) {
      final iid = int.tryParse(body['ingredient']['id'].toString());
      if (iid != null) {
        updates.add('ingredient_id = CAST(@ingredient_id AS int4)');
        values['ingredient_id'] = iid;
      }
    }

    if (updates.isEmpty) {
      return Response.badRequest(body: {'error': 'No fields to update'});
    }

    try {
      final sql = 'UPDATE _recipeingredient SET ${updates.join(', ')} WHERE id = @id';
      await store.execute(sql, substitutionValues: values);

      final selectSql = 'SELECT ri.id, ri.count, i.id, i.name, r.id, r.name '
          'FROM _recipeingredient ri '
          'JOIN _ingredient i ON i.id = ri.ingredient_id '
          'JOIN _recipe r ON r.id = ri.recipe_id '
          'WHERE ri.id = @id';
      final rows = await store.execute(selectSql, substitutionValues: {'id': id}) as List<List<dynamic>>;
      if (rows.isEmpty) {
        return Response.serverError(body: {'error': 'Updated recipe ingredient not found'});
      }
      final row = rows.first;
      return Response.ok({
        'id': row[0],
        'count': row[1],
        'ingredient': {'id': row[2], 'name': row[3]},
        'recipe': {'id': row[4], 'name': row[5]},
      });
    } catch (e) {
      return Response.badRequest(body: {'error': 'Invalid recipe or ingredient ID: $e'});
    }
  }

  @Operation.delete('id')
  Future<Response> deleteRecipeIngredient(@Bind.path('id') int id) async {
    final query = Query<RecipeIngredient>(context)
      ..where((ri) => ri.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'RecipeIngredient not found'});
    }
    
    return Response.ok({'message': 'RecipeIngredient deleted successfully'});
  }

  @Operation.post('batch')
  Future<Response> batchCreateRecipeIngredients() async {
    // Читаем JSON array вручную для поддержки вложенных объектов
    final List<dynamic> ingredients = await request!.body.decode();

    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final insertedIds = <int>[];
      for (final item in ingredients) {
        final recipeId = int.tryParse(item['recipe']?['id']?.toString() ?? '');
        final ingredientId = int.tryParse(item['ingredient']?['id']?.toString() ?? '');
        final num? countNum = () {
          final rc = item['count'];
          if (rc is num) return rc;
          if (rc is String) return num.tryParse(rc);
          return null;
        }();
        if (recipeId == null || ingredientId == null || countNum == null) {
          return Response.badRequest(body: {'error': 'recipe.id, ingredient.id and count are required'});
        }
        final values = <String, dynamic>{
          'count': countNum.toInt(),
          'ingredient_id': ingredientId,
          'recipe_id': recipeId,
        };
        final insertSql = 'INSERT INTO _recipeingredient (count, ingredient_id, recipe_id) '
            'VALUES (CAST(@count AS int4), CAST(@ingredient_id AS int4), CAST(@recipe_id AS int4)) RETURNING id';
        final inserted = await store.execute(insertSql, substitutionValues: values) as List<List<dynamic>>;
        if (inserted.isNotEmpty) {
          insertedIds.add(inserted.first.first as int);
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final rid in insertedIds) {
        final selectSql = 'SELECT ri.id, ri.count, i.id, i.name, r.id, r.name '
            'FROM _recipeingredient ri '
            'JOIN _ingredient i ON i.id = ri.ingredient_id '
            'JOIN _recipe r ON r.id = ri.recipe_id '
            'WHERE ri.id = @id';
        final rows = await store.execute(selectSql, substitutionValues: {'id': rid}) as List<List<dynamic>>;
        if (rows.isNotEmpty) {
          final row = rows.first;
          results.add({
            'id': row[0],
            'count': row[1],
            'ingredient': {'id': row[2], 'name': row[3]},
            'recipe': {'id': row[4], 'name': row[5]},
          });
        }
      }
      return Response.ok(results);
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }

  @Operation.delete('recipe', 'recipeId')
  Future<Response> deleteAllIngredientsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<RecipeIngredient>(context)
      ..where((ri) => ri.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    return Response.ok({'message': 'Deleted $deletedCount ingredients for recipe'});
  }

  @Operation.get('recipeId')
  Future<Response> getIngredientsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT ri.id, ri.count, i.id, i.name '
      'FROM _recipeingredient ri JOIN _ingredient i ON i.id = ri.ingredient_id '
      'WHERE ri.recipe_id = @rid ORDER BY ri.id',
      substitutionValues: {'rid': recipeId},
    ) as List<List<dynamic>>;
    final list = rows.map((r) => {
      'id': r[0],
      'count': r[1],
      'ingredient': {'id': r[2], 'name': r[3]},
    }).toList();
    return Response.ok(list);
  }
}

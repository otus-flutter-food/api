import 'dart:convert';

import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/ingredient.dart';
import '../model/recipe.dart';
import 'base_controller.dart';

class RecipeController extends ResourceController {
  RecipeController(this.context);
  
  final ManagedContext context;
  
  @Operation.post()
  Future<Response> createRecipe() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("Received body: $body");
    
    final name = body['name'] as String?;
    final duration = body['duration'] as int?;
    final photo = body['photo'] as String?;
    
    if (name == null || duration == null) {
      return Response.badRequest(body: {"error": "name and duration are required"});
    }
    
    try {
      // Используем прямой SQL запрос из-за проблемы с типами в Conduit
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final conn = await store.execute(
        "INSERT INTO _recipe (name, duration, photo) VALUES (@name, @duration, @photo) RETURNING id, name, duration, photo",
        substitutionValues: {
          'name': name,
          'duration': duration,
          'photo': photo
        }
      ) as List<List<dynamic>>;
      
      if (conn.isNotEmpty && conn.first.length >= 4) {
        final row = conn.first;
        return Response.ok({
          'id': row[0],
          'name': row[1],
          'duration': row[2],
          'photo': row[3]
        });
      }
      
      return Response.serverError(body: {"error": "Failed to insert recipe"});
    } catch (e) {
      print("Error inserting recipe: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.get()
  Future<Response> getAllRecipes(
    @Bind.query('page') int? page,
    @Bind.query('limit') int? limit,
    @Bind.query('search') String? search,
    @Bind.query('category') String? category,
    @Bind.query('minTime') int? minTime,
    @Bind.query('maxTime') int? maxTime,
  ) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      // Pagination defaults
      final pageNum = page ?? 1;
      final pageSize = limit ?? 20;
      final offset = (pageNum - 1) * pageSize;
      
      // Build WHERE clause
      final conditions = <String>[];
      final values = <String, dynamic>{};
      
      if (search != null && search.isNotEmpty) {
        conditions.add("name ILIKE @search");
        values['search'] = '%$search%';
      }
      
      if (minTime != null) {
        conditions.add("duration >= @minTime");
        values['minTime'] = minTime;
      }
      
      if (maxTime != null) {
        conditions.add("duration <= @maxTime");
        values['maxTime'] = maxTime;
      }
      
      final whereClause = conditions.isNotEmpty 
        ? 'WHERE ${conditions.join(' AND ')}' 
        : '';
      
      // Count total recipes
      final countQuery = "SELECT COUNT(*) FROM _recipe $whereClause";
      final countResult = await store.execute(countQuery, substitutionValues: values) as List<List<dynamic>>;
      final totalCount = countResult.first.first as int;
      
      // Fetch recipes with pagination
      values['limit'] = pageSize;
      values['offset'] = offset;
      
      final sql = """
        SELECT r.id, r.name, r.duration, r.photo,
               COUNT(DISTINCT rsl.id) as steps_count,
               COUNT(DISTINCT ri.id) as ingredients_count
        FROM _recipe r
        LEFT JOIN _recipesteplink rsl ON rsl.recipe_id = r.id
        LEFT JOIN _recipeingredient ri ON ri.recipe_id = r.id
        $whereClause
        GROUP BY r.id, r.name, r.duration, r.photo
        ORDER BY r.id DESC
        LIMIT @limit OFFSET @offset
      """;
      
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      final recipes = result.map((row) => {
        'id': row[0],
        'name': row[1],
        'duration': row[2],
        'photo': row[3],
        'stepsCount': row[4],
        'ingredientsCount': row[5],
      }).toList();
      
      return Response.ok({
        'data': recipes,
        'pagination': {
          'page': pageNum,
          'limit': pageSize,
          'total': totalCount,
          'totalPages': (totalCount / pageSize).ceil(),
        }
      });
    } catch (e) {
      print("Error fetching recipes: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.get('id')
  Future<Response> getRecipeByID(@Bind.path('id') int id) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      // Get recipe with related data
      final recipeSql = """
        SELECT r.id, r.name, r.duration, r.photo
        FROM _recipe r
        WHERE r.id = @id
      """;
      
      final recipeResult = await store.execute(
        recipeSql, 
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      if (recipeResult.isEmpty) {
        return Response.notFound(body: {"error": "Recipe not found"});
      }
      
      final recipeRow = recipeResult.first;
      
      // Get steps
      final stepsSql = """
        SELECT s.id, s.name, s.duration, rsl.number
        FROM _recipesteplink rsl
        JOIN _recipestep s ON s.id = rsl.step_id
        WHERE rsl.recipe_id = @id
        ORDER BY rsl.number
      """;
      
      final stepsResult = await store.execute(
        stepsSql, 
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      final steps = stepsResult.map((row) => {
        'id': row[0],
        'name': row[1],
        'duration': row[2],
        'number': row[3],
      }).toList();
      
      // Get ingredients
      final ingredientsSql = """
        SELECT i.id, i.name, ri.count, mu.name as unit
        FROM _recipeingredient ri
        JOIN _ingredient i ON i.id = ri.ingredient_id
        LEFT JOIN _measureunit mu ON mu.id = i.measureUnit_id
        WHERE ri.recipe_id = @id
      """;
      
      final ingredientsResult = await store.execute(
        ingredientsSql,
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      final ingredients = ingredientsResult.map((row) => {
        'id': row[0],
        'name': row[1],
        'count': row[2],
        'unit': row[3],
      }).toList();
      
      // Get comments count
      final commentsSql = "SELECT COUNT(*) FROM _comment WHERE recipe_id = @id";
      final commentsResult = await store.execute(
        commentsSql,
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      final commentsCount = commentsResult.first.first as int;
      
      final recipe = {
        'id': recipeRow[0],
        'name': recipeRow[1],
        'duration': recipeRow[2],
        'photo': recipeRow[3],
        'steps': steps,
        'ingredients': ingredients,
        'commentsCount': commentsCount,
      };
      
      return Response.ok(recipe);
    } catch (e) {
      print("Error fetching recipe: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.put('id')
  Future<Response> updateRecipe(@Bind.path('id') int id) async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("PUT /recipe/$id - Received body: $body");
    
    try {
      // Проверяем существование рецепта
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final checkSql = "SELECT id FROM _recipe WHERE id = @id";
      final checkResult = await store.execute(
        checkSql,
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      if (checkResult.isEmpty) {
        return Response.notFound(body: {"error": "Recipe not found"});
      }
      
      // Используем прямой SQL для обновления
      final updates = <String>[];
      final values = <String, dynamic>{'id': id};
      
      if (body.containsKey('name')) {
        updates.add('name = @name');
        values['name'] = body['name'];
      }
      if (body.containsKey('duration')) {
        updates.add('duration = @duration');
        values['duration'] = body['duration'];
      }
      if (body.containsKey('photo')) {
        updates.add('photo = @photo');
        values['photo'] = body['photo'];
      }
      
      if (updates.isEmpty) {
        return Response.badRequest(body: {"error": "No fields to update"});
      }
      
      final sql = "UPDATE _recipe SET ${updates.join(', ')} WHERE id = @id RETURNING id, name, duration, photo";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty && result.first.length >= 4) {
        final row = result.first;
        return Response.ok({
          'id': row[0],
          'name': row[1],
          'duration': row[2],
          'photo': row[3]
        });
      }
      
      return Response.serverError(body: {"error": "Failed to update recipe"});
    } catch (e) {
      print("Error updating recipe: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.delete('id')
  Future<Response> deleteRecipe(@Bind.path('id') int id) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      // Delete in order: comments, recipe_ingredients, recipe_step_links, then recipe
      await store.execute(
        "DELETE FROM _comment WHERE recipe_id = @id",
        substitutionValues: {'id': id}
      );
      
      await store.execute(
        "DELETE FROM _recipeingredient WHERE recipe_id = @id",
        substitutionValues: {'id': id}
      );
      
      await store.execute(
        "DELETE FROM _recipesteplink WHERE recipe_id = @id",
        substitutionValues: {'id': id}
      );
      
      final result = await store.execute(
        "DELETE FROM _recipe WHERE id = @id RETURNING id",
        substitutionValues: {'id': id}
      ) as List<List<dynamic>>;
      
      if (result.isEmpty) {
        return Response.notFound(body: {"error": "Recipe not found"});
      }
      
      return Response.ok({"message": "Recipe deleted successfully", "id": result.first.first});
    } catch (e) {
      print("Error deleting recipe: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}

class RecipeSearchController extends ResourceController {
  RecipeSearchController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> searchRecipes(
    @Bind.query('q') String? query,
    @Bind.query('category') String? category,
    @Bind.query('ingredients') String? ingredients,
    @Bind.query('maxTime') int? maxTime,
    @Bind.query('page') int? page,
    @Bind.query('limit') int? limit,
  ) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      final pageNum = page ?? 1;
      final pageSize = limit ?? 20;
      final offset = (pageNum - 1) * pageSize;
      
      final conditions = <String>[];
      final values = <String, dynamic>{};
      
      if (query != null && query.isNotEmpty) {
        conditions.add("(r.name ILIKE @query OR EXISTS (SELECT 1 FROM _recipestep s JOIN _recipesteplink rsl ON s.id = rsl.step_id WHERE rsl.recipe_id = r.id AND s.name ILIKE @query))");
        values['query'] = '%$query%';
      }
      
      if (maxTime != null) {
        conditions.add("r.duration <= @maxTime");
        values['maxTime'] = maxTime;
      }
      
      if (ingredients != null && ingredients.isNotEmpty) {
        final ingredientList = ingredients.split(',').map((i) => i.trim()).toList();
        conditions.add("""
          EXISTS (
            SELECT 1 FROM _recipeingredient ri 
            JOIN _ingredient i ON i.id = ri.ingredient_id 
            WHERE ri.recipe_id = r.id AND i.name ILIKE ANY(@ingredients)
          )
        """);
        values['ingredients'] = ingredientList.map((i) => '%$i%').toList();
      }
      
      final whereClause = conditions.isNotEmpty 
        ? 'WHERE ${conditions.join(' AND ')}' 
        : '';
      
      values['limit'] = pageSize;
      values['offset'] = offset;
      
      final sql = """
        SELECT r.id, r.name, r.duration, r.photo
        FROM _recipe r
        $whereClause
        ORDER BY r.name
        LIMIT @limit OFFSET @offset
      """;
      
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      final recipes = result.map((row) => {
        'id': row[0],
        'name': row[1],
        'duration': row[2],
        'photo': row[3],
      }).toList();
      
      // Count total
      final countSql = "SELECT COUNT(*) FROM _recipe r $whereClause";
      final countResult = await store.execute(countSql, substitutionValues: values) as List<List<dynamic>>;
      final total = countResult.first.first as int;
      
      return Response.ok({
        'data': recipes,
        'pagination': {
          'page': pageNum,
          'limit': pageSize,
          'total': total,
          'totalPages': (total / pageSize).ceil(),
        }
      });
    } catch (e) {
      print("Error searching recipes: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}

class RecipeStepController extends BaseController<RecipeStep> {
  RecipeStepController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_recipestep';
  
  @override
  List<String> get columns => ['id', 'name', 'duration'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'name': row[1],
      'duration': row[2]
    };
  }
}

class RecipeStepLinksController extends BaseController<RecipeStepLink> {
  RecipeStepLinksController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_recipesteplink';
  
  @override
  List<String> get columns => ['id', 'number', 'recipe_id', 'step_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'number': row[1],
      'recipe': row[2] != null ? {'id': row[2]} : null,
      'step': row[3] != null ? {'id': row[3]} : null
    };
  }
}

class RecipeIngredientController extends BaseController<RecipeIngredient> {
  RecipeIngredientController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_recipeingredient';
  
  @override
  List<String> get columns => ['id', 'count', 'ingredient_id', 'recipe_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'count': row[1],
      'ingredient': row[2] != null ? {'id': row[2]} : null,
      'recipe': row[3] != null ? {'id': row[3]} : null
    };
  }
}
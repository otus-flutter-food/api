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
  Future<Response> getAllRecipes() async {
    final query = Query<Recipe>(context);
    final recipes = await query.fetch();
    return Response.ok(recipes);
  }
  
  @Operation.get('id')
  Future<Response> getRecipeByID(@Bind.path('id') int id) async {
    final query = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(id);
    
    final recipe = await query.fetchOne();
    
    if (recipe == null) {
      return Response.notFound();
    }
    
    return Response.ok(recipe);
  }
  
  @Operation.put('id')
  Future<Response> updateRecipe(@Bind.path('id') int id) async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("PUT /recipe/$id - Received body: $body");
    
    try {
      // Проверяем существование рецепта
      final checkQuery = Query<Recipe>(context)
        ..where((r) => r.id).equalTo(id);
      final existing = await checkQuery.fetchOne();
      
      if (existing == null) {
        return Response.notFound();
      }
      
      // Используем прямой SQL для обновления
      final store = context.persistentStore as PostgreSQLPersistentStore;
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
      final query = Query<Recipe>(context)
        ..where((r) => r.id).equalTo(id);
      
      final deletedCount = await query.delete();
      
      if (deletedCount == 0) {
        return Response.notFound();
      }
      
      return Response.ok({"message": "Recipe deleted successfully"});
    } catch (e) {
      print("Error deleting recipe: $e");
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
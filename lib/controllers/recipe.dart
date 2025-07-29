import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/ingredient.dart';
import '../model/recipe.dart';

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
}

class RecipeStepController extends ManagedObjectController<RecipeStep> {
  RecipeStepController(ManagedContext context) : super(context);
}

class RecipeStepLinksController extends ManagedObjectController<RecipeStepLink> {
  RecipeStepLinksController(ManagedContext context) : super(context);
}

class RecipeIngredientController extends ManagedObjectController<RecipeIngredient> {
  RecipeIngredientController(ManagedContext context) : super(context);
}
import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:foodapi/model/ingredient.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeIngredientController extends ResourceController {
  RecipeIngredientController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getAllRecipeIngredients(
    @Bind.query('recipeId') int? recipeId,
    @Bind.query('ingredientId') int? ingredientId,
  ) async {
    final query = Query<RecipeIngredient>(context)
      ..join(object: (ri) => ri.ingredient)
      ..join(object: (ri) => ri.recipe);
    
    if (recipeId != null) {
      query.where((ri) => ri.recipe!.id).equalTo(recipeId);
    }
    
    if (ingredientId != null) {
      query.where((ri) => ri.ingredient!.id).equalTo(ingredientId);
    }
    
    final recipeIngredients = await query.fetch();
    return Response.ok(recipeIngredients);
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
  Future<Response> createRecipeIngredient(@Bind.body(ignore: ['id']) RecipeIngredient recipeIngredient) async {
    final query = Query<RecipeIngredient>(context)
      ..values = recipeIngredient;
    
    final inserted = await query.insert();
    
    final fetchQuery = Query<RecipeIngredient>(context)
      ..where((ri) => ri.id).equalTo(inserted.id)
      ..join(object: (ri) => ri.ingredient)
      ..join(object: (ri) => ri.recipe);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
  }

  @Operation.put('id')
  Future<Response> updateRecipeIngredient(
    @Bind.path('id') int id,
    @Bind.body() RecipeIngredient recipeIngredient,
  ) async {
    final query = Query<RecipeIngredient>(context)
      ..where((ri) => ri.id).equalTo(id)
      ..values = recipeIngredient;
    
    final updated = await query.updateOne();
    
    if (updated == null) {
      return Response.notFound(body: {'error': 'RecipeIngredient not found'});
    }
    
    final fetchQuery = Query<RecipeIngredient>(context)
      ..where((ri) => ri.id).equalTo(id)
      ..join(object: (ri) => ri.ingredient)
      ..join(object: (ri) => ri.recipe);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
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
  Future<Response> batchCreateRecipeIngredients(@Bind.body() List<Map<String, dynamic>> ingredients) async {
    final results = <RecipeIngredient>[];
    
    await context.transaction((transaction) async {
      for (final ingredient in ingredients) {
        final recipeIngredient = RecipeIngredient()
          ..recipe = Recipe()..id = ingredient['recipeId'] as int
          ..ingredient = Ingredient()..id = ingredient['ingredientId'] as int
          ..count = ingredient['count'] as int?;
        
        final query = Query<RecipeIngredient>(transaction)
          ..values = recipeIngredient;
        
        final inserted = await query.insert();
        results.add(inserted);
      }
    });
    
    return Response.ok(results);
  }

  @Operation.delete('recipe', 'recipeId')
  Future<Response> deleteAllIngredientsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<RecipeIngredient>(context)
      ..where((ri) => ri.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    return Response.ok({'message': 'Deleted $deletedCount ingredients for recipe'});
  }
}
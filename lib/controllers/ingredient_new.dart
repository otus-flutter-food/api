import 'package:conduit_core/conduit_core.dart';
import '../model/ingredient.dart';
import '../model/freezer.dart';

class IngredientController extends ResourceController {
  IngredientController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getAllIngredients() async {
    final query = Query<Ingredient>(context)
      ..join(object: (i) => i.measureUnit);
    
    final ingredients = await query.fetch();
    
    return Response.ok(ingredients.map((i) => i.asMap()).toList());
  }
  
  @Operation.get('id')
  Future<Response> getIngredientByID(@Bind.path('id') int id) async {
    final query = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(id)
      ..join(object: (i) => i.measureUnit);
    
    final ingredient = await query.fetchOne();
    
    if (ingredient == null) {
      return Response.notFound(body: {'error': 'Ingredient not found'});
    }
    
    return Response.ok(ingredient.asMap());
  }
  
  @Operation.post()
  Future<Response> createIngredient(@Bind.body() Ingredient ingredient) async {
    // Validate measureUnit exists
    if (ingredient.measureUnit?.id != null) {
      final unitQuery = Query<MeasureUnit>(context)
        ..where((u) => u.id).equalTo(ingredient.measureUnit!.id!);
      
      final unit = await unitQuery.fetchOne();
      if (unit == null) {
        return Response.badRequest(body: {'error': 'Invalid measureUnit ID'});
      }
    }
    
    final query = Query<Ingredient>(context)
      ..values = ingredient;
    
    final insertedIngredient = await query.insert();
    
    // Fetch with measureUnit joined
    final resultQuery = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(insertedIngredient.id!)
      ..join(object: (i) => i.measureUnit);
    
    final result = await resultQuery.fetchOne();
    
    return Response.ok(result?.asMap() ?? insertedIngredient.asMap());
  }
  
  @Operation.put('id')
  Future<Response> updateIngredient(
    @Bind.path('id') int id,
    @Bind.body() Ingredient updatedIngredient,
  ) async {
    // Validate measureUnit if provided
    if (updatedIngredient.measureUnit?.id != null) {
      final unitQuery = Query<MeasureUnit>(context)
        ..where((u) => u.id).equalTo(updatedIngredient.measureUnit!.id!);
      
      final unit = await unitQuery.fetchOne();
      if (unit == null) {
        return Response.badRequest(body: {'error': 'Invalid measureUnit ID'});
      }
    }
    
    final query = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(id)
      ..values = updatedIngredient;
    
    final ingredient = await query.updateOne();
    
    if (ingredient == null) {
      return Response.notFound(body: {'error': 'Ingredient not found'});
    }
    
    // Fetch with measureUnit joined
    final resultQuery = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(id)
      ..join(object: (i) => i.measureUnit);
    
    final result = await resultQuery.fetchOne();
    
    return Response.ok(result?.asMap() ?? ingredient.asMap());
  }
  
  @Operation.delete('id')
  Future<Response> deleteIngredient(@Bind.path('id') int id) async {
    // Check if used in recipes
    final recipeQuery = Query<RecipeIngredient>(context)
      ..where((ri) => ri.ingredient!.id).equalTo(id);
    
    final recipeCount = await recipeQuery.reduce.count();
    
    if (recipeCount > 0) {
      return Response.conflict(body: {
        'error': 'Cannot delete ingredient that is used in recipes',
        'count': recipeCount
      });
    }
    
    // Check if in freezer
    final freezerQuery = Query<Freezer>(context)
      ..where((f) => f.ingredient!.id).equalTo(id);
    
    final freezerCount = await freezerQuery.reduce.count();
    
    if (freezerCount > 0) {
      return Response.conflict(body: {
        'error': 'Cannot delete ingredient that is in freezer',
        'count': freezerCount
      });
    }
    
    // Delete ingredient
    final query = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Ingredient not found'});
    }
    
    return Response.ok({'message': 'Ingredient deleted successfully', 'id': id});
  }
}
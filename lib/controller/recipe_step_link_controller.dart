import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeStepLinkController extends ResourceController {
  RecipeStepLinkController(this.context);

  final ManagedContext context;

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
  Future<Response> createRecipeStepLink(@Bind.body(ignore: ['id']) RecipeStepLink link) async {
    final query = Query<RecipeStepLink>(context)
      ..values = link;
    
    final inserted = await query.insert();
    
    final fetchQuery = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.id).equalTo(inserted.id)
      ..join(object: (rsl) => rsl.recipe)
      ..join(object: (rsl) => rsl.step);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
  }

  @Operation.put('id')
  Future<Response> updateRecipeStepLink(
    @Bind.path('id') int id,
    @Bind.body() RecipeStepLink link,
  ) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.id).equalTo(id)
      ..values = link;
    
    final updated = await query.updateOne();
    
    if (updated == null) {
      return Response.notFound(body: {'error': 'RecipeStepLink not found'});
    }
    
    final fetchQuery = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.id).equalTo(id)
      ..join(object: (rsl) => rsl.recipe)
      ..join(object: (rsl) => rsl.step);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
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

  @Operation.get('recipe', 'recipeId')
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
    final results = <RecipeStepLink>[];
    
    await context.transaction((transaction) async {
      for (final link in links) {
        final recipeStepLink = RecipeStepLink()
          ..recipe = Recipe()..id = link['recipeId'] as int
          ..step = RecipeStep()..id = link['stepId'] as int
          ..number = link['number'] as int?;
        
        final query = Query<RecipeStepLink>(transaction)
          ..values = recipeStepLink;
        
        final inserted = await query.insert();
        results.add(inserted);
      }
    });
    
    return Response.ok(results);
  }

  @Operation.post('reorder')
  Future<Response> reorderSteps(@Bind.body() Map<String, dynamic> body) async {
    final recipeId = body['recipeId'] as int?;
    final stepOrders = body['stepOrders'] as List<dynamic>?;
    
    if (recipeId == null || stepOrders == null) {
      return Response.badRequest(
        body: {'error': 'recipeId and stepOrders are required'},
      );
    }
    
    await context.transaction((transaction) async {
      for (final order in stepOrders) {
        final linkId = order['linkId'] as int;
        final newNumber = order['number'] as int;
        
        final query = Query<RecipeStepLink>(transaction)
          ..where((rsl) => rsl.id).equalTo(linkId)
          ..where((rsl) => rsl.recipe!.id).equalTo(recipeId)
          ..values.number = newNumber;
        
        await query.updateOne();
      }
    });
    
    return Response.ok({'message': 'Steps reordered successfully'});
  }

  @Operation.delete('recipe', 'recipeId')
  Future<Response> deleteAllStepsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    return Response.ok({'message': 'Deleted $deletedCount steps for recipe'});
  }
}
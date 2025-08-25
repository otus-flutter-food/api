import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:foodapi/model/recipe.dart';

class RecipeStepController extends ResourceController {
  RecipeStepController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getAllSteps() async {
    final query = Query<RecipeStep>(context)
      ..join(set: (s) => s.recipeStepLinks);
    
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
  Future<Response> createStep(@Bind.body(ignore: ['id']) RecipeStep step) async {
    final query = Query<RecipeStep>(context)
      ..values = step;
    
    final insertedStep = await query.insert();
    return Response.ok(insertedStep);
  }

  @Operation.put('id')
  Future<Response> updateStep(
    @Bind.path('id') int id,
    @Bind.body() RecipeStep step,
  ) async {
    final query = Query<RecipeStep>(context)
      ..where((s) => s.id).equalTo(id)
      ..values = step;
    
    final updatedStep = await query.updateOne();
    
    if (updatedStep == null) {
      return Response.notFound(body: {'error': 'Step not found'});
    }
    
    return Response.ok(updatedStep);
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

  @Operation.get('search')
  Future<Response> searchSteps(@Bind.query('name') String? name) async {
    final query = Query<RecipeStep>(context);
    
    if (name != null && name.isNotEmpty) {
      query.where((s) => s.name).contains(name, caseSensitive: false);
    }
    
    final steps = await query.fetch();
    return Response.ok(steps);
  }
}
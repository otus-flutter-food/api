import 'package:conduit/conduit.dart';
import '../model/recipe.dart';

// class RecipeController extends ManagedObjectController<Recipe> {
//   RecipeController(ManagedContext context) : super(context);
// }
class RecipeController extends ResourceController {
  RecipeController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getAllRecipe() async {
    final query = Query<Recipe>(context)
      ..join(set: (i) => i.recipeIngredients)
          .join(object: (i) => i.ingredient)
          .join(object: (m) => m.measureUnit)
      ..join(set: (s) => s.recipeStepLinks).join(object: (s) => s.step)
      ..join(set: (f) => f.favoriteRecipes) //.join(object: (f) => f)
      ..join(set: (c) => c.comments)
          .join(object: (u) => u.user)
          .returningProperties((x) => [x.username, x.avatar]);
    // ..join(set: (i) => i.recipeIngredients).join(object: (i) => i.ingredient)
    // ..join(set: (s) => s.recipeStepLinks).join(object: (s) => s.step)
    // ..join(set: (f) => f.favoriteRecipes) //.join(object: (f) => f.recipe)
    // ..join(set: (c) => c.comments); //.join(object: (c) => c.recipe);
    final recipe = await query.fetch();

    return Response.ok(recipe);
  }

  @Operation.get('id')
  Future<Response> getRecipeById() async {
    final id = int.parse(request?.path.variables['id'] ?? "");
    try {
      final query = Query<Recipe>(context)
        ..where((t) => t.id).equalTo(id)
        ..join(set: (i) => i.recipeIngredients)
            .join(object: (i) => i.ingredient)
            .join(object: (m) => m.measureUnit)
        ..join(set: (s) => s.recipeStepLinks).join(object: (s) => s.step)
        ..join(set: (f) => f.favoriteRecipes) //.join(object: (f) => f)
        ..join(set: (c) => c.comments)
            .join(object: (u) => u.user)
            .returningProperties(
                (x) => [x.username, x.avatar]); //.join(object: (c) => c);
      final recipe = await query.fetch();

      return Response.ok(recipe);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @Operation.delete('id')
  Future<Response> deleteRecipeById() async {
    final id = int.parse(request?.path.variables['id'] ?? "");
    var query = Query<Recipe>(context)..where((u) => u.id).equalTo(id);

    int? recipeDeleted = await query.delete();

    return Response.ok(recipeDeleted);
  }

  @Operation.post()
  Future<Response> createRecipe(@Bind.body() Recipe recipe) async {
    try {
      late Recipe? insertedRecipe;

      insertedRecipe = await context.insertObject(recipe);

      return Response.ok(insertedRecipe);
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @Operation.put()
  Future<Response> updateRecipe(@Bind.body() Recipe recipe) async {
    final query = Query<Recipe>(context)
      ..where((t) => t.id).equalTo(recipe.id)
      ..values.name = recipe.name
      ..values.photo = recipe.photo
      ..values.duration = recipe.duration;

    // //Обновить фавориты
    // if (recipe.favoriteRecipes!.isNotEmpty) {
    //   final query = Query<Favorite>(context)
    //     ..where((u) => u.recipe!.id).equalTo(recipe.id);
    //   //Удалить
    //   int? favoriteDeleted = await query.delete();

    //   //Создать новых фаритов
    //   recipe.favoriteRecipes!.forEach((favorite) async {
    //     final newFavorite = Favorite()
    //       ..id = favorite.id
    //       ..recipe = favorite.recipe
    //       ..user = favorite.user;
    //     final query = Query<Favorite>(context)..values = newFavorite;
    //     await query.insert();
    //   });
    // }

    // //Обновить ингредиенты
    // if (recipe.recipeIngredients!.isNotEmpty) {
    //   final query = Query<RecipeIngredient>(context)
    //     ..where((i) => i.recipe!.id).equalTo(recipe.id);

    //   int? recipeIngredientsDeleted = await query.delete();

    //   recipe.recipeIngredients!.forEach((recipeIngredient) async {
    //     final newRecipeIngredients = RecipeIngredient()
    //       ..id = recipeIngredient.id
    //       ..recipe = recipeIngredient.recipe
    //       ..ingredient = recipeIngredient.ingredient;
    //     final query = Query<RecipeIngredient>(context)
    //       ..values = newRecipeIngredients;
    //     await query.insert();
    //   });
    // }

    // //Обновить шаги
    // if (recipe.recipeStepLinks!.isNotEmpty) {
    //   final query = Query<RecipeStepLink>(context)
    //     ..where((stepLink) => stepLink.recipe!.id).equalTo(recipe.id);

    //   int? recipeStepLinkDeleted = await query.delete();

    //   recipe.recipeStepLinks!.forEach((recipeStepLink) async {
    //     final newRecipeStepLinks = RecipeStepLink()
    //       ..id = recipeStepLink.id
    //       ..recipe = recipeStepLink.recipe
    //       ..step = recipeStepLink.step;
    //     final query = Query<RecipeStepLink>(context)
    //       ..values = newRecipeStepLinks;
    //     await query.insert();
    //   });
    //}

    final updateRecipe = await query.update();

    return Response.ok(updateRecipe);
  }
}

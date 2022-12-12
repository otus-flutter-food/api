import 'package:conduit/conduit.dart';
import 'package:foodapi/model/recipe.dart';

import '../model/favorite.dart';

class FavoriteController extends ManagedObjectController<Favorite> {
  FavoriteController(ManagedContext context) : super(context);
}

class FavoritesController extends ResourceController {
  FavoritesController(this.context);

  final ManagedContext context;

  @Operation.get('id')
  Future<Response> getFavorites() async {
    final id = int.parse(request?.path.variables['id'] ?? "");
    final query = Query<Recipe>(context)..join(set: (f) => f.favoriteRecipes);

    final recipe = await query.fetch();
    final filterRecipe = recipe
        .where((r) => r.favoriteRecipes!.any((f) => f.user?.id == id))
        .toList();
    final Response response = Response.ok(filterRecipe);

    return response;
  }
}

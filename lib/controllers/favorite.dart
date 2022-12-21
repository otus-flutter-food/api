import 'package:conduit/conduit.dart';
// import 'package:foodapi/model/recipe.dart';

import '../model/favorite.dart';

class FavoriteController extends ManagedObjectController<Favorite> {
  FavoriteController(ManagedContext context) : super(context);
}

class FavoritesController extends ResourceController {
  FavoritesController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post('id')
  Future<Response> deleteFavorite() async {
    try {
      final id = int.parse(request?.path.variables['id'] ?? "");

      final query = Query<Favorite>(managedContext)
        ..where((f) => f.id).equalTo(id);

      final int? usersDeleted = await query.delete();

      final Response response = Response.ok(usersDeleted);

      return response;
    } catch (e) {
      return Response.serverError(body: e);
    }
  }
}
//   @Operation.post()
//   Future<Response> createFavorite(@Bind.body() Favorite favorite) async {
//     late final int id;
//     await managedContext.transaction((transaction) async {
//       final qCreateFavorite = Query<Favorite>(transaction)
//         ..values.recipe = favorite.recipe
//         ..values.user = favorite.user;
//       final createdFavorite = await qCreateFavorite.insert();
//       id = createdFavorite.id!;
//     });
//     final Response response = Response.ok(id);

//     return response;
//   }

  // @Operation.get('id')
  // Future<Response> getFavorites() async {
  //   final id = int.parse(request?.path.variables['id'] ?? "");
  //   final query = Query<Recipe>(context)..join(set: (f) => f.favoriteRecipes);

  //   final recipe = await query.fetch();
  //   final filterRecipe = recipe
  //       .where((r) => r.favoriteRecipes!.any((f) => f.user?.id == id))
  //       .toList();
  //   final Response response = Response.ok(filterRecipe);

  //   return response;
  // }
// }

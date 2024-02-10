import 'package:conduit_core/conduit_core.dart';

import 'recipe.dart';
import 'user.dart';

class Favorite extends ManagedObject<_Favorite> implements _Favorite {}

class _Favorite {
  @primaryKey
  int? id;

  @Relate(#favoriteRecipes)
  Recipe? recipe;

  @Relate(#favoriteRecipes)
  User? user;
}

import 'package:conduit/conduit.dart';

import 'favorite.dart';
import 'ingredient.dart';

class Recipe extends ManagedObject<_Recipe> implements _Recipe {}

class _Recipe {
  @primaryKey
  int? id;

  @Column()
  String? name;

  @Column()
  int? duration;      //in seconds

  @Column()
  String? photo;

  ManagedSet<RecipeIngredient>? recipeIngredients;

  ManagedSet<RecipeStepLink>? recipeStepLinks;

  ManagedSet<Favorite>? favoriteRecipes;
  
  ManagedSet<Comment>? comments;
}

class RecipeStep extends ManagedObject<_RecipeStep> implements _RecipeStep {}

class _RecipeStep {
  @primaryKey
  int? id;

  @Column()
  String? name;

  @Column()
  int? duration;    //in seconds

  ManagedSet<RecipeStepLink>? recipeStepLinks;
}


class RecipeStepLink extends ManagedObject<_RecipeStepLink> implements _RecipeStepLink {}

class _RecipeStepLink {
  @primaryKey
  int? id;

  @Relate(#recipeStepLinks)
  Recipe? recipe;

  @Relate(#recipeStepLinks)
  RecipeStep? step;

  @Column()
  int? number;
}

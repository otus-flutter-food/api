import 'package:conduit_core/conduit_core.dart';

import 'freezer.dart';
import 'recipe.dart';

class MeasureUnit extends ManagedObject<_MeasureUnit> implements _MeasureUnit {}

class _MeasureUnit {
  @primaryKey
  int? id;

  @Column()
  String? one;      //1, 21, 31, ...

  @Column()
  String? few;      //2-4, 22-24, 32-34, ...

  @Column()
  String? many;     //остальные (в т.ч. 11 и 12)

  ManagedSet<Ingredient>? ingredients;
}

class Ingredient extends ManagedObject<_Ingredient> implements _Ingredient {}

class _Ingredient {
  @primaryKey
  int? id;

  @Column()
  String? name;

  @Column()
  double? caloriesForUnit;

  @Relate(#ingredients)
  MeasureUnit? measureUnit;

  ManagedSet<RecipeIngredient>? recipeIngredients;

  ManagedSet<Freezer>? ingredientFreezer;
}

class RecipeIngredient extends ManagedObject<_RecipeIngredient> implements _RecipeIngredient {}

class _RecipeIngredient {
  @primaryKey
  int? id;

  @Relate(#recipeIngredients)
  Ingredient? ingredient;

  @Relate(#recipeIngredients)
  Recipe? recipe;

  @Column()
  int? count;
}

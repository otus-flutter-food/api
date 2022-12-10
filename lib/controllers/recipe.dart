import 'package:conduit/conduit.dart';

import '../model/ingredient.dart';
import '../model/recipe.dart';

class RecipeController extends ManagedObjectController<Recipe> {
  RecipeController(ManagedContext context) : super(context);
}

class RecipeStepController extends ManagedObjectController<RecipeStep> {
  RecipeStepController(ManagedContext context) : super(context);
}

class RecipeStepLinksController extends ManagedObjectController<RecipeStepLink> {
  RecipeStepLinksController(ManagedContext context) : super(context);
}

class RecipeIngredientController extends ManagedObjectController<RecipeIngredient> {
  RecipeIngredientController(ManagedContext context) : super(context);
}
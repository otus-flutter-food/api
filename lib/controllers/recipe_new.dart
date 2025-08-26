import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import '../model/recipe.dart';
import '../model/ingredient.dart';
import '../model/comment.dart';
import '../model/favorite.dart';

class RecipeController extends ResourceController {
  RecipeController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список рецептов", context.schema['Recipe']),
        "404": APIResponse("Рецепт не найден")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Рецепт создан", context.schema['Recipe']),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Рецепт обновлён", context.schema['Recipe']),
        "404": APIResponse("Рецепт не найден"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Рецепт успешно удалён"),
        "404": APIResponse("Рецепт не найден")
      };
    }
    return {};
  }
  
  @Operation.post()
  Future<Response> createRecipe(@Bind.body() Recipe recipe) async {
    final query = Query<Recipe>(context)
      ..values = recipe;
    
    final insertedRecipe = await query.insert();
    return Response.ok(insertedRecipe);
  }
  
  @Operation.get()
  Future<Response> getAllRecipes({
    @Bind.query('page') int? page,
    @Bind.query('limit') int? limit,
    @Bind.query('search') String? search,
    @Bind.query('minTime') int? minTime,
    @Bind.query('maxTime') int? maxTime,
  }) async {
    final pageNum = page ?? 1;
    final pageSize = limit ?? 20;
    final offset = (pageNum - 1) * pageSize;
    
    final query = Query<Recipe>(context)
      ..offset = offset
      ..fetchLimit = pageSize
      ..sortBy((r) => r.id, QuerySortOrder.descending);
    
    // Add search filter
    if (search != null && search.isNotEmpty) {
      query.where((r) => r.name).contains(search, caseSensitive: false);
    }
    
    // Add time filters
    if (minTime != null) {
      query.where((r) => r.duration).greaterThanEqualTo(minTime);
    }
    if (maxTime != null) {
      query.where((r) => r.duration).lessThanEqualTo(maxTime);
    }
    
    // Count total for pagination
    final countQuery = Query<Recipe>(context);
    if (search != null && search.isNotEmpty) {
      countQuery.where((r) => r.name).contains(search, caseSensitive: false);
    }
    if (minTime != null) {
      countQuery.where((r) => r.duration).greaterThanEqualTo(minTime);
    }
    if (maxTime != null) {
      countQuery.where((r) => r.duration).lessThanEqualTo(maxTime);
    }
    final totalCount = await countQuery.reduce.count();
    
    final recipes = await query.fetch();
    
    return Response.ok({
      'data': recipes.map((r) => r.asMap()).toList(),
      'pagination': {
        'page': pageNum,
        'limit': pageSize,
        'total': totalCount,
        'totalPages': (totalCount / pageSize).ceil(),
      }
    });
  }
  
  @Operation.get('id')
  Future<Response> getRecipeByID(@Bind.path('id') int id) async {
    final query = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(id)
      ..join(set: (r) => r.recipeStepLinks)
        .join(object: (rsl) => rsl.step)
      ..join(set: (r) => r.recipeIngredients)
        .join(object: (ri) => ri.ingredient)
          .join(object: (i) => i.measureunit)
      ..join(set: (r) => r.comments);
    
    final recipe = await query.fetchOne();
    
    if (recipe == null) {
      return Response.notFound(body: {'error': 'Recipe not found'});
    }
    
    // Sort steps by number
    if (recipe.recipeStepLinks != null) {
      final sortedLinks = recipe.recipeStepLinks!.toList()
        ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
      recipe.recipeStepLinks = ManagedSet.from(sortedLinks);
    }
    
    return Response.ok(recipe);
  }
  
  @Operation.put('id')
  Future<Response> updateRecipe(
    @Bind.path('id') int id,
    @Bind.body() Recipe updatedRecipe,
  ) async {
    final query = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(id)
      ..values = updatedRecipe;
    
    final recipe = await query.updateOne();
    
    if (recipe == null) {
      return Response.notFound(body: {'error': 'Recipe not found'});
    }
    
    return Response.ok(recipe);
  }
  
  @Operation.delete('id')
  Future<Response> deleteRecipe(@Bind.path('id') int id) async {
    // Delete related data first (due to foreign key constraints)
    // Comments
    final commentsQuery = Query<Comment>(context)
      ..where((c) => c.recipe!.id).equalTo(id);
    await commentsQuery.delete();
    
    // Recipe ingredients
    final ingredientsQuery = Query<RecipeIngredient>(context)
      ..where((ri) => ri.recipe!.id).equalTo(id);
    await ingredientsQuery.delete();
    
    // Recipe step links
    final stepsQuery = Query<RecipeStepLink>(context)
      ..where((rsl) => rsl.recipe!.id).equalTo(id);
    await stepsQuery.delete();
    
    // Favorites
    final favoritesQuery = Query<Favorite>(context)
      ..where((f) => f.recipe!.id).equalTo(id);
    await favoritesQuery.delete();
    
    // Finally delete the recipe
    final query = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Recipe not found'});
    }
    
    return Response.ok({'message': 'Recipe deleted successfully', 'id': id});
  }
}

class RecipeSearchController extends ResourceController {
  RecipeSearchController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Результаты поиска рецептов", context.schema['Recipe']),
        "400": APIResponse("Неверные параметры поиска")
      };
    }
    return {};
  }
  
  @Operation.get()
  Future<Response> searchRecipes({
    @Bind.query('q') String? query,
    @Bind.query('ingredients') String? ingredients,
    @Bind.query('maxTime') int? maxTime,
    @Bind.query('page') int? page,
    @Bind.query('limit') int? limit,
  }) async {
    final pageNum = page ?? 1;
    final pageSize = limit ?? 20;
    final offset = (pageNum - 1) * pageSize;
    
    final recipeQuery = Query<Recipe>(context)
      ..offset = offset
      ..fetchLimit = pageSize
      ..sortBy((r) => r.name, QuerySortOrder.ascending);
    
    // Search by name or in steps
    if (query != null && query.isNotEmpty) {
      recipeQuery.where((r) => r.name).contains(query, caseSensitive: false);
    }
    
    // Filter by max time
    if (maxTime != null) {
      recipeQuery.where((r) => r.duration).lessThanEqualTo(maxTime);
    }
    
    // Filter by ingredients - this would need a more complex join
    // For now, we'll fetch all and filter in memory (not ideal for large datasets)
    if (ingredients != null && ingredients.isNotEmpty) {
      final ingredientList = ingredients.split(',').map((i) => i.trim().toLowerCase()).toList();
      recipeQuery.join(set: (r) => r.recipeIngredients)
        .join(object: (ri) => ri.ingredient);
    }
    
    final recipes = await recipeQuery.fetch();
    
    // Filter by ingredients if specified (in-memory filtering)
    List<Recipe> filteredRecipes = recipes;
    if (ingredients != null && ingredients.isNotEmpty) {
      final ingredientList = ingredients.split(',').map((i) => i.trim().toLowerCase()).toList();
      filteredRecipes = recipes.where((recipe) {
        final recipeIngredients = recipe.recipeIngredients ?? [];
        return recipeIngredients.any((ri) {
          final ingredientName = ri.ingredient?.name?.toLowerCase() ?? '';
          return ingredientList.any((searchIngredient) => 
            ingredientName.contains(searchIngredient));
        });
      }).toList();
    }
    
    // Count total
    final countQuery = Query<Recipe>(context);
    if (query != null && query.isNotEmpty) {
      countQuery.where((r) => r.name).contains(query, caseSensitive: false);
    }
    if (maxTime != null) {
      countQuery.where((r) => r.duration).lessThanEqualTo(maxTime);
    }
    final totalCount = await countQuery.reduce.count();
    
    return Response.ok({
      'data': filteredRecipes.map((r) => r.asMap()).toList(),
      'pagination': {
        'page': pageNum,
        'limit': pageSize,
        'total': totalCount,
        'totalPages': (totalCount / pageSize).ceil(),
      }
    });
  }
}

// User-specific controller that will require authentication
class UserRecipesController extends ResourceController {
  UserRecipesController(this.context);
  
  final ManagedContext context;
  
  @Operation.get('favorites')
  Future<Response> getUserFavorites() async {
    // TODO: Get user from auth token
    // For now, return error
    return Response.unauthorized(body: {'error': 'Authentication required'});
  }
  
  @Operation.post('id', 'favorite')
  Future<Response> addToFavorites(@Bind.path('id') int recipeId) async {
    // TODO: Get user from auth token
    // For now, return error
    return Response.unauthorized(body: {'error': 'Authentication required'});
  }
  
  @Operation.delete('id', 'favorite')
  Future<Response> removeFromFavorites(@Bind.path('id') int recipeId) async {
    // TODO: Get user from auth token
    // For now, return error
    return Response.unauthorized(body: {'error': 'Authentication required'});
  }
}
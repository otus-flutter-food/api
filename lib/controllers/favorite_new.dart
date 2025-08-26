import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import '../model/favorite.dart';
import '../model/user.dart';
import '../model/recipe.dart';

class FavoriteController extends ResourceController {
  FavoriteController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список избранных рецептов", context.schema['Favorite']),
        "404": APIResponse("Избранное не найдено")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Рецепт добавлен в избранное", context.schema['Favorite']),
        "400": APIResponse("Ошибка валидации (неверный user ID или recipe ID)"),
        "409": APIResponse("Рецепт уже в избранном")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Рецепт удалён из избранного"),
        "404": APIResponse("Избранное не найдено")
      };
    }
    return {};
  }
  
  @Operation.get()
  Future<Response> getAllFavorites() async {
    final query = Query<Favorite>(context)
      ..join(object: (f) => f.user)
      ..join(object: (f) => f.recipe);
    
    final favorites = await query.fetch();
    
    return Response.ok(favorites.map((f) => f.asMap()).toList());
  }
  
  @Operation.get('id')
  Future<Response> getFavoriteByID(@Bind.path('id') int id) async {
    final query = Query<Favorite>(context)
      ..where((f) => f.id).equalTo(id)
      ..join(object: (f) => f.user)
      ..join(object: (f) => f.recipe);
    
    final favorite = await query.fetchOne();
    
    if (favorite == null) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok(favorite.asMap());
  }
  
  @Operation.post()
  Future<Response> createFavorite(@Bind.body() Favorite favorite) async {
    // Validate user exists
    if (favorite.user?.id != null) {
      final userQuery = Query<User>(context)
        ..where((u) => u.id).equalTo(favorite.user!.id!);
      
      final user = await userQuery.fetchOne();
      if (user == null) {
        return Response.badRequest(body: {'error': 'Invalid user ID'});
      }
    }
    
    // Validate recipe exists
    if (favorite.recipe?.id != null) {
      final recipeQuery = Query<Recipe>(context)
        ..where((r) => r.id).equalTo(favorite.recipe!.id!);
      
      final recipe = await recipeQuery.fetchOne();
      if (recipe == null) {
        return Response.badRequest(body: {'error': 'Invalid recipe ID'});
      }
    }
    
    // Check if already favorited
    final existingQuery = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(favorite.user!.id!)
      ..where((f) => f.recipe!.id).equalTo(favorite.recipe!.id!);
    
    final existing = await existingQuery.fetchOne();
    if (existing != null) {
      return Response.conflict(body: {'error': 'Recipe already in favorites'});
    }
    
    // Create favorite
    final query = Query<Favorite>(context)
      ..values = favorite;
    
    final insertedFavorite = await query.insert();
    
    // Fetch with joins
    final resultQuery = Query<Favorite>(context)
      ..where((f) => f.id).equalTo(insertedFavorite.id!)
      ..join(object: (f) => f.user)
      ..join(object: (f) => f.recipe);
    
    final result = await resultQuery.fetchOne();
    
    return Response.ok(result?.asMap() ?? insertedFavorite.asMap());
  }
  
  @Operation.delete('id')
  Future<Response> deleteFavorite(@Bind.path('id') int id) async {
    final query = Query<Favorite>(context)
      ..where((f) => f.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok({'message': 'Favorite removed successfully', 'id': id});
  }
  
  // Additional endpoints for user favorites
  @Operation.get('user', 'userId')
  Future<Response> getUserFavorites(@Bind.path('userId') int userId) async {
    final query = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(userId)
      ..join(object: (f) => f.recipe);
    
    final favorites = await query.fetch();
    
    return Response.ok(favorites.map((f) => f.asMap()).toList());
  }
  
  // Delete favorite by user and recipe
  @Operation.delete('user', 'userId', 'recipe', 'recipeId')
  Future<Response> deleteFavoriteByUserAndRecipe(
    @Bind.path('userId') int userId,
    @Bind.path('recipeId') int recipeId,
  ) async {
    final query = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(userId)
      ..where((f) => f.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok({'message': 'Favorite removed successfully'});
  }
}
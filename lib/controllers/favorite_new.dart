import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import '../model/favorite.dart';

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
        "200": APIResponse.schema("Список избранных рецептов", APISchemaObject.array(ofSchema: context.schema['Favorite'])),
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
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, u.id as user_id, r.id as recipe_id, r.name '
      'FROM _favorite f '
      'JOIN _user u ON u.id = f.user_id '
      'JOIN _recipe r ON r.id = f.recipe_id'
    ) as List<List<dynamic>>;
    final data = rows.map((r) => {
      'id': r[0],
      'user': {'id': r[1]},
      'recipe': {'id': r[2], 'name': r[3]},
    }).toList();
    return Response.ok(data);
  }
  
  @Operation.get('id')
  Future<Response> getFavoriteByID(@Bind.path('id') int id) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, u.id as user_id, r.id as recipe_id, r.name '
      'FROM _favorite f '
      'JOIN _user u ON u.id = f.user_id '
      'JOIN _recipe r ON r.id = f.recipe_id '
      'WHERE f.id = @id',
      substitutionValues: {'id': id},
    ) as List<List<dynamic>>;
    if (rows.isEmpty) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    final r = rows.first;
    return Response.ok({
      'id': r[0],
      'user': {'id': r[1]},
      'recipe': {'id': r[2], 'name': r[3]},
    });
  }
  
  @Operation.post()
  Future<Response> createFavorite() async {
    final Map<String, dynamic> body = await request!.body.decode();
    final userId = int.tryParse((body['userId'] ?? body['user']?['id'])?.toString() ?? '');
    final recipeId = int.tryParse((body['recipeId'] ?? body['recipe']?['id'])?.toString() ?? '');
    if (userId == null || recipeId == null) {
      return Response.badRequest(body: {'error': 'userId/user.id and recipeId/recipe.id are required'});
    }
    final store = context.persistentStore as PostgreSQLPersistentStore;
    // Validate existence
    final u = await store.execute('SELECT 1 FROM _user WHERE id=@id LIMIT 1', substitutionValues: {'id': userId});
    if (u.isEmpty) return Response.badRequest(body: {'error': 'Invalid user ID'});
    final r = await store.execute('SELECT 1 FROM _recipe WHERE id=@id LIMIT 1', substitutionValues: {'id': recipeId});
    if (r.isEmpty) return Response.badRequest(body: {'error': 'Invalid recipe ID'});
    // Check duplicate
    final dup = await store.execute(
      'SELECT 1 FROM _favorite WHERE user_id=@uid AND recipe_id=@rid LIMIT 1',
      substitutionValues: {'uid': userId, 'rid': recipeId},
    );
    if (dup.isNotEmpty) return Response.conflict(body: {'error': 'Recipe already in favorites'});
    // Insert
    final rows = await store.execute(
      'INSERT INTO _favorite (user_id, recipe_id) '
      'VALUES (CAST(@uid AS int4), CAST(@rid AS int4)) RETURNING id',
      substitutionValues: {'uid': userId, 'rid': recipeId},
    ) as List<List<dynamic>>;
    final id = rows.first.first as int;
    final out = await store.execute(
      'SELECT f.id, u.id as user_id, r.id as recipe_id, r.name '
      'FROM _favorite f JOIN _user u ON u.id=f.user_id JOIN _recipe r ON r.id=f.recipe_id '
      'WHERE f.id=@id', substitutionValues: {'id': id}) as List<List<dynamic>>;
    final row = out.first;
    return Response.ok({'id': row[0], 'user': {'id': row[1]}, 'recipe': {'id': row[2], 'name': row[3]}});
  }
  
  @Operation.delete('id')
  Future<Response> deleteFavorite(@Bind.path('id') int id) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final res = await store.execute('DELETE FROM _favorite WHERE id = @id', substitutionValues: {'id': id});
    // Postgres driver returns empty result; check rowCount unavailable; do a confirm
    final check = await store.execute('SELECT 1 FROM _favorite WHERE id = @id', substitutionValues: {'id': id});
    if (check.isNotEmpty) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok({'message': 'Favorite removed successfully', 'id': id});
  }
  
  // Additional endpoints for user favorites
  @Operation.get('user', 'userId')
  Future<Response> getUserFavorites(@Bind.path('userId') int userId) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT f.id, r.id as recipe_id, r.name '
      'FROM _favorite f JOIN _recipe r ON r.id = f.recipe_id '
      'WHERE f.user_id = @uid', substitutionValues: {'uid': userId}) as List<List<dynamic>>;
    final data = rows.map((r) => {'id': r[0], 'recipe': {'id': r[1], 'name': r[2]}}).toList();
    return Response.ok(data);
  }
  
  // Delete favorite by user and recipe
  @Operation.delete('user', 'userId', 'recipe', 'recipeId')
  Future<Response> deleteFavoriteByUserAndRecipe(
    @Bind.path('userId') int userId,
    @Bind.path('recipeId') int recipeId,
  ) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    await store.execute('DELETE FROM _favorite WHERE user_id=@uid AND recipe_id=@rid', substitutionValues: {'uid': userId, 'rid': recipeId});
    final check = await store.execute('SELECT 1 FROM _favorite WHERE user_id=@uid AND recipe_id=@rid LIMIT 1', substitutionValues: {'uid': userId, 'rid': recipeId});
    if (check.isNotEmpty) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok({'message': 'Favorite removed successfully'});
  }
}

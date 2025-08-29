import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import '../model/user.dart';
import '../model/recipe.dart';
import '../model/favorite.dart';
import '../model/comment.dart';

class UserProfileController extends ResourceController {
  UserProfileController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getProfile() async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    // Return user profile without sensitive data
    final profile = {
      'id': user.id,
      'login': user.login,
      // Public API uses camelCase keys
      'firstName': user.firstName,
      'lastName': user.lastName,
      'phone': user.phone,
      'avatarUrl': user.avatarUrl,
      'birthday': user.birthday?.toIso8601String(),
      // Don't return password or token
    };
    
    // Remove null values for cleaner response
    profile.removeWhere((key, value) => value == null);
    
    return Response.ok(profile);
  }
  
  @Operation.put()
  Future<Response> updateProfile(@Bind.body() Map<String, dynamic> updates) async {
    final user = request!.attachments['user'] as User?;
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final sets = <String>[];
    final vals = <String, dynamic>{'id': user.id};
    if (updates.containsKey('password')) { sets.add('password = @password'); vals['password'] = updates['password']; }
    if (updates.containsKey('firstName')) { sets.add('first_name = @first_name'); vals['first_name'] = updates['firstName']; }
    if (updates.containsKey('lastName')) { sets.add('last_name = @last_name'); vals['last_name'] = updates['lastName']; }
    if (updates.containsKey('phone')) { sets.add('phone = @phone'); vals['phone'] = updates['phone']; }
    if (updates.containsKey('avatarUrl')) { sets.add('avatar_url = @avatar_url'); vals['avatar_url'] = updates['avatarUrl']; }
    if (updates.containsKey('birthday')) { sets.add('birthday = @birthday'); vals['birthday'] = updates['birthday']; }
    if (sets.isEmpty) {
      return Response.badRequest(body: {'error': 'No fields to update'});
    }
    await store.execute('UPDATE _user SET ' + sets.join(', ') + ' WHERE id = @id', substitutionValues: vals);
    final rows = await store.execute(
      'SELECT id, login, first_name, last_name, phone, avatar_url, birthday FROM _user WHERE id=@id',
      substitutionValues: {'id': user.id},
    ) as List<List<dynamic>>;
    if (rows.isEmpty) return Response.serverError(body: {'error': 'Failed to load profile'});
    final r = rows.first;
    final profile = {
      'id': r[0],
      'login': r[1],
      'firstName': r[2],
      'lastName': r[3],
      'phone': r[4],
      'avatarUrl': r[5],
      'birthday': (r[6] as DateTime?)?.toIso8601String(),
      'message': 'Profile updated successfully'
    };
    profile.removeWhere((k, v) => v == null);
    return Response.ok(profile);
  }
  
  @Operation.post()
  Future<Response> logout() async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    // Clear token
    final query = Query<User>(context)
      ..where((u) => u.id).equalTo(user.id!)
      ..values.token = null;
    
    await query.updateOne();
    
    return Response.ok({'message': 'Logged out successfully'});
  }
}

class UserFavoritesController extends ResourceController {
  UserFavoritesController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getFavorites() async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    final query = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(user.id!)
      ..join(object: (f) => f.recipe);
    
    final favorites = await query.fetch();
    
    final recipes = favorites.map((f) => f.recipe?.asMap()).toList();
    
    return Response.ok(recipes);
  }
  
  @Operation.post('recipeId')
  Future<Response> addFavorite(@Bind.path('recipeId') int recipeId) async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    // Check if recipe exists
    final recipeQuery = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(recipeId);
    
    final recipe = await recipeQuery.fetchOne();
    
    if (recipe == null) {
      return Response.notFound(body: {'error': 'Recipe not found'});
    }
    
    // Check if already favorited
    final existingQuery = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(user.id!)
      ..where((f) => f.recipe!.id).equalTo(recipeId);
    
    final existing = await existingQuery.fetchOne();
    
    if (existing != null) {
      return Response.conflict(body: {'error': 'Recipe already in favorites'});
    }
    
    // Add to favorites
    final insertQuery = Query<Favorite>(context)
      ..values.user = user
      ..values.recipe = recipe;
    
    final favorite = await insertQuery.insert();
    
    return Response.ok({
      'message': 'Recipe added to favorites',
      'favorite': favorite.asMap()
    });
  }
  
  @Operation.delete('recipeId')
  Future<Response> removeFavorite(@Bind.path('recipeId') int recipeId) async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    final query = Query<Favorite>(context)
      ..where((f) => f.user!.id).equalTo(user.id!)
      ..where((f) => f.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Favorite not found'});
    }
    
    return Response.ok({'message': 'Recipe removed from favorites'});
  }
}

class UserCommentsController extends ResourceController {
  UserCommentsController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getUserComments() async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    final query = Query<Comment>(context)
      ..where((c) => c.user!.id).equalTo(user.id!)
      ..join(object: (c) => c.recipe);
    
    final comments = await query.fetch();
    
    return Response.ok(comments.map((c) => c.asMap()).toList());
  }
  
  @Operation.post()
  Future<Response> createComment(@Bind.body() Map<String, dynamic> body) async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    final recipeId = body['recipeId'] as int?;
    final text = body['text'] as String?;
    
    if (recipeId == null || text == null || text.isEmpty) {
      return Response.badRequest(body: {'error': 'recipeId and text are required'});
    }
    
    // Check if recipe exists
    final recipeQuery = Query<Recipe>(context)
      ..where((r) => r.id).equalTo(recipeId);
    
    final recipe = await recipeQuery.fetchOne();
    
    if (recipe == null) {
      return Response.notFound(body: {'error': 'Recipe not found'});
    }
    
    // Create comment via raw SQL to avoid ORM type issues
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'INSERT INTO _comment (user_id, recipe_id, text, date_time) '
      'VALUES (CAST(@uid AS int4), CAST(@rid AS int4), @text, NOW()) RETURNING id',
      substitutionValues: {'uid': user.id, 'rid': recipeId, 'text': text},
    ) as List<List<dynamic>>;
    final id = rows.first.first as int;
    final result = await store.execute(
      'SELECT c.id, c.text, c.photo, c.date_time, u.id as user_id, r.id as recipe_id, r.name '
      'FROM _comment c JOIN _user u ON u.id=c.user_id JOIN _recipe r ON r.id=c.recipe_id '
      'WHERE c.id=@id', substitutionValues: {'id': id}) as List<List<dynamic>>;
    final r = result.first;
    return Response.ok({
      'id': r[0], 'text': r[1], 'photo': r[2], 'dateTime': (r[3] as DateTime?)?.toIso8601String(),
      'user': {'id': r[4]}, 'recipe': {'id': r[5], 'name': r[6]},
    });
  }
  
  @Operation.delete('id')
  Future<Response> deleteComment(@Bind.path('id') int commentId) async {
    final user = request!.attachments['user'] as User?;
    
    if (user == null) {
      return Response.unauthorized(body: {'error': 'Authentication required'});
    }
    
    // Check if comment belongs to user
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(commentId)
      ..where((c) => c.user!.id).equalTo(user.id!);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Comment not found or does not belong to you'});
    }
    
    return Response.ok({'message': 'Comment deleted successfully'});
  }
}

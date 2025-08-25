import 'package:conduit_core/conduit_core.dart';
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
      // Production schema fields
      'first_name': user.firstName,
      'last_name': user.lastName,
      'phone': user.phone,
      'avatar_url': user.avatarUrl,
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
    
    final query = Query<User>(context)
      ..where((u) => u.id).equalTo(user.id!);
    
    // Allow updating profile fields
    if (updates.containsKey('password')) {
      query.values.password = updates['password'] as String;
    }
    if (updates.containsKey('first_name')) {
      query.values.firstName = updates['first_name'] as String?;
    }
    if (updates.containsKey('last_name')) {
      query.values.lastName = updates['last_name'] as String?;
    }
    if (updates.containsKey('phone')) {
      query.values.phone = updates['phone'] as String?;
    }
    if (updates.containsKey('avatar_url')) {
      query.values.avatarUrl = updates['avatar_url'] as String?;
    }
    if (updates.containsKey('birthday')) {
      final birthdayStr = updates['birthday'] as String?;
      if (birthdayStr != null) {
        query.values.birthday = DateTime.parse(birthdayStr);
      }
    }
    
    final updatedUser = await query.updateOne();
    
    if (updatedUser == null) {
      return Response.serverError(body: {'error': 'Failed to update profile'});
    }
    
    final profile = {
      'id': updatedUser.id,
      'login': updatedUser.login,
      'first_name': updatedUser.firstName,
      'last_name': updatedUser.lastName,
      'phone': updatedUser.phone,
      'avatar_url': updatedUser.avatarUrl,
      'birthday': updatedUser.birthday?.toIso8601String(),
      'message': 'Profile updated successfully'
    };
    
    // Remove null values
    profile.removeWhere((key, value) => value == null);
    
    return Response.ok(profile);
  }
  
  @Operation.post('logout')
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
    
    // Create comment
    final query = Query<Comment>(context)
      ..values.text = text
      ..values.dateTime = DateTime.now()
      ..values.user = user
      ..values.recipe = recipe;
    
    final comment = await query.insert();
    
    return Response.ok(comment.asMap());
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
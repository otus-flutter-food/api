import 'package:foodapi/foodapi.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:foodapi/model/comment.dart';
import 'package:foodapi/model/recipe.dart';
import 'package:foodapi/model/user.dart';

class CommentController extends ResourceController {
  CommentController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getAllComments(
    @Bind.query('recipeId') int? recipeId,
    @Bind.query('userId') int? userId,
  ) async {
    final query = Query<Comment>(context)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    if (recipeId != null) {
      query.where((c) => c.recipe!.id).equalTo(recipeId);
    }
    
    if (userId != null) {
      query.where((c) => c.user!.id).equalTo(userId);
    }
    
    query.sortBy((c) => c.dateTime, QuerySortOrder.descending);
    
    final comments = await query.fetch();
    return Response.ok(comments);
  }

  @Operation.get('id')
  Future<Response> getCommentById(@Bind.path('id') int id) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final comment = await query.fetchOne();
    
    if (comment == null) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    return Response.ok(comment);
  }

  @Operation.post()
  Future<Response> createComment(@Bind.body(ignore: ['id']) Comment comment) async {
    comment.dateTime ??= DateTime.now();
    
    final query = Query<Comment>(context)
      ..values = comment;
    
    final inserted = await query.insert();
    
    final fetchQuery = Query<Comment>(context)
      ..where((c) => c.id).equalTo(inserted.id)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
  }

  @Operation.put('id')
  Future<Response> updateComment(
    @Bind.path('id') int id,
    @Bind.body() Comment comment,
  ) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..values = comment;
    
    final updated = await query.updateOne();
    
    if (updated == null) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    final fetchQuery = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final result = await fetchQuery.fetchOne();
    return Response.ok(result);
  }

  @Operation.delete('id')
  Future<Response> deleteComment(@Bind.path('id') int id) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    return Response.ok({'message': 'Comment deleted successfully'});
  }

  @Operation.get('recipe', 'recipeId')
  Future<Response> getCommentsByRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<Comment>(context)
      ..where((c) => c.recipe!.id).equalTo(recipeId)
      ..join(object: (c) => c.user)
      ..sortBy((c) => c.dateTime, QuerySortOrder.descending);
    
    final comments = await query.fetch();
    return Response.ok(comments);
  }

  @Operation.get('user', 'userId')
  Future<Response> getCommentsByUser(@Bind.path('userId') int userId) async {
    final query = Query<Comment>(context)
      ..where((c) => c.user!.id).equalTo(userId)
      ..join(object: (c) => c.recipe)
      ..sortBy((c) => c.dateTime, QuerySortOrder.descending);
    
    final comments = await query.fetch();
    return Response.ok(comments);
  }

  @Operation.delete('recipe', 'recipeId')
  Future<Response> deleteAllCommentsForRecipe(@Bind.path('recipeId') int recipeId) async {
    final query = Query<Comment>(context)
      ..where((c) => c.recipe!.id).equalTo(recipeId);
    
    final deletedCount = await query.delete();
    
    return Response.ok({'message': 'Deleted $deletedCount comments for recipe'});
  }
}
import 'package:conduit_core/conduit_core.dart';
import '../model/comment.dart';
import '../model/user.dart';
import '../model/recipe.dart';

class CommentController extends ResourceController {
  CommentController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getAllComments({
    @Bind.query('recipeId') int? recipeId,
    @Bind.query('userId') int? userId,
  }) async {
    final query = Query<Comment>(context)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe)
      ..sortBy((c) => c.dateTime, QuerySortOrder.descending);
    
    if (recipeId != null) {
      query.where((c) => c.recipe!.id).equalTo(recipeId);
    }
    
    if (userId != null) {
      query.where((c) => c.user!.id).equalTo(userId);
    }
    
    final comments = await query.fetch();
    
    return Response.ok(comments.map((c) => c.asMap()).toList());
  }
  
  @Operation.get('id')
  Future<Response> getCommentByID(@Bind.path('id') int id) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final comment = await query.fetchOne();
    
    if (comment == null) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    return Response.ok(comment.asMap());
  }
  
  @Operation.post()
  Future<Response> createComment(@Bind.body() Comment comment) async {
    // Validate user exists
    if (comment.user?.id != null) {
      final userQuery = Query<User>(context)
        ..where((u) => u.id).equalTo(comment.user!.id!);
      
      final user = await userQuery.fetchOne();
      if (user == null) {
        return Response.badRequest(body: {'error': 'Invalid user ID'});
      }
    }
    
    // Validate recipe exists
    if (comment.recipe?.id != null) {
      final recipeQuery = Query<Recipe>(context)
        ..where((r) => r.id).equalTo(comment.recipe!.id!);
      
      final recipe = await recipeQuery.fetchOne();
      if (recipe == null) {
        return Response.badRequest(body: {'error': 'Invalid recipe ID'});
      }
    }
    
    // Set dateTime if not provided
    if (comment.dateTime == null) {
      comment.dateTime = DateTime.now();
    }
    
    // Create comment
    final query = Query<Comment>(context)
      ..values = comment;
    
    final insertedComment = await query.insert();
    
    // Fetch with joins
    final resultQuery = Query<Comment>(context)
      ..where((c) => c.id).equalTo(insertedComment.id!)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final result = await resultQuery.fetchOne();
    
    return Response.ok(result?.asMap() ?? insertedComment.asMap());
  }
  
  @Operation.put('id')
  Future<Response> updateComment(
    @Bind.path('id') int id,
    @Bind.body() Comment updatedComment,
  ) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..values = updatedComment;
    
    final comment = await query.updateOne();
    
    if (comment == null) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    // Fetch with joins
    final resultQuery = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id)
      ..join(object: (c) => c.user)
      ..join(object: (c) => c.recipe);
    
    final result = await resultQuery.fetchOne();
    
    return Response.ok(result?.asMap() ?? comment.asMap());
  }
  
  @Operation.delete('id')
  Future<Response> deleteComment(@Bind.path('id') int id) async {
    final query = Query<Comment>(context)
      ..where((c) => c.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    
    return Response.ok({'message': 'Comment deleted successfully', 'id': id});
  }
}
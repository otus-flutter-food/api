import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import '../model/comment.dart';

class CommentController extends ResourceController {
  CommentController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список комментариев", APISchemaObject.array(ofSchema: context.schema['Comment'])),
        "404": APIResponse("Комментарий не найден")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Комментарий создан", context.schema['Comment']),
        "400": APIResponse("Ошибка валидации (неверный recipe ID) или отсутствует авторизация")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Комментарий обновлён", context.schema['Comment']),
        "404": APIResponse("Комментарий не найден"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Комментарий успешно удалён"),
        "404": APIResponse("Комментарий не найден")
      };
    }
    return {};
  }
  
  @override
  APIRequestBody? documentOperationRequestBody(context, Operation? operation) {
    if (operation?.method == "POST") {
      return APIRequestBody.schema(
        APISchemaObject.object({
          "recipe": APISchemaObject.object({"id": APISchemaObject.integer()}),
          "text": APISchemaObject.string(),
          "photo": APISchemaObject.string()..isNullable = true,
        }),
        description: "Данные комментария (автор определяется из токена авторизации)",
      );
    } else if (operation?.method == "PUT") {
      return APIRequestBody.schema(
        APISchemaObject.object({
          "text": APISchemaObject.string()..isNullable = true,
          "photo": APISchemaObject.string()..isNullable = true,
        }),
        description: "Обновленные данные комментария",
      );
    }
    return null;
  }
  
  @Operation.get()
  Future<Response> getAllComments({
    @Bind.query('recipeId') int? recipeId,
    @Bind.query('userId') int? userId,
  }) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final where = <String>[];
    final values = <String, dynamic>{};
    if (recipeId != null) { where.add('c.recipe_id = @recipeId'); values['recipeId'] = recipeId; }
    if (userId != null) { where.add('c.user_id = @userId'); values['userId'] = userId; }
    final sql = 'SELECT c.id, c.text, c.photo, c.date_time, u.id as user_id, r.id as recipe_id, r.name '
        'FROM _comment c '
        'JOIN _user u ON u.id = c.user_id '
        'JOIN _recipe r ON r.id = c.recipe_id '
        '${where.isNotEmpty ? 'WHERE ' + where.join(' AND ') : ''} '
        'ORDER BY c.date_time DESC';
    final rows = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
    final data = rows.map((r) => {
      'id': r[0],
      'text': r[1],
      'photo': r[2],
      'dateTime': r[3]?.toString(),
      'user': {'id': r[4]},
      'recipe': {'id': r[5], 'name': r[6]},
    }).toList();
    return Response.ok(data);
  }
  
  @Operation.get('id')
  Future<Response> getCommentByID(@Bind.path('id') int id) async {
    final store = context.persistentStore as PostgreSQLPersistentStore;
    final rows = await store.execute(
      'SELECT c.id, c.text, c.photo, c.date_time, u.id as user_id, r.id as recipe_id, r.name '
      'FROM _comment c JOIN _user u ON u.id=c.user_id JOIN _recipe r ON r.id=c.recipe_id '
      'WHERE c.id=@id', substitutionValues: {'id': id}) as List<List<dynamic>>;
    if (rows.isEmpty) {
      return Response.notFound(body: {'error': 'Comment not found'});
    }
    final r = rows.first;
    return Response.ok({
      'id': r[0], 'text': r[1], 'photo': r[2], 'dateTime': r[3]?.toString(),
      'user': {'id': r[4]}, 'recipe': {'id': r[5], 'name': r[6]},
    });
  }
  
  @Operation.post()
  Future<Response> createComment() async {
    final Map<String, dynamic> body = await request!.body.decode();
    
    // Получаем userId из токена авторизации (если есть)
    int? userId;
    final authHeader = request!.raw.headers['authorization']?.first;
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final userRows = await store.execute(
        'SELECT id FROM _user WHERE token = @token',
        substitutionValues: {'token': token}
      ) as List<List<dynamic>>;
      if (userRows.isNotEmpty) {
        userId = userRows.first.first as int;
      }
    }
    
    // Если токена нет, пытаемся получить userId из body (для обратной совместимости)
    if (userId == null) {
      userId = int.tryParse((body['userId'] ?? body['user']?['id'])?.toString() ?? '');
    }
    
    final recipeId = int.tryParse((body['recipeId'] ?? body['recipe']?['id'])?.toString() ?? '');
    final text = body['text']?.toString();
    final photo = body['photo']?.toString();
    if (userId == null || recipeId == null || text == null) {
      return Response.badRequest(body: {'error': 'Authorization required or userId/user.id must be provided. recipeId/recipe.id and text are required'});
    }
    final store = context.persistentStore as PostgreSQLPersistentStore;
    // Validate ids
    final u = await store.execute('SELECT 1 FROM _user WHERE id=@id LIMIT 1', substitutionValues: {'id': userId});
    if (u.isEmpty) return Response.badRequest(body: {'error': 'Invalid user ID'});
    final r = await store.execute('SELECT 1 FROM _recipe WHERE id=@id LIMIT 1', substitutionValues: {'id': recipeId});
    if (r.isEmpty) return Response.badRequest(body: {'error': 'Invalid recipe ID'});
    // Insert
    final rows = await store.execute(
      'INSERT INTO _comment (user_id, recipe_id, text, photo, date_time) '
      'VALUES (CAST(@uid AS int4), CAST(@rid AS int4), @text, @photo, NOW()) '
      'RETURNING id',
      substitutionValues: {'uid': userId, 'rid': recipeId, 'text': text, 'photo': photo},
    ) as List<List<dynamic>>;
    final id = rows.first.first as int;
    return await getCommentByID(id);
  }
  
  @Operation.put('id')
  Future<Response> updateComment(
    @Bind.path('id') int id,
  ) async {
    final Map<String, dynamic> body = await request!.body.decode();
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};
    if (body.containsKey('text')) { updates.add('text = @text'); values['text'] = body['text'].toString(); }
    if (body.containsKey('photo')) { updates.add('photo = @photo'); values['photo'] = body['photo']?.toString(); }
    if (updates.isEmpty) return Response.badRequest(body: {'error': 'No fields to update'});
    final store = context.persistentStore as PostgreSQLPersistentStore;
    await store.execute('UPDATE _comment SET ${updates.join(', ')} WHERE id = @id', substitutionValues: values);
    return await getCommentByID(id);
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

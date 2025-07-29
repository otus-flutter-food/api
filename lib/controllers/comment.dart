import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/comment.dart';
import 'base_controller.dart';

class CommentController extends BaseController<Comment> {
  CommentController(ManagedContext context) : super(context);
  
  @override
  @Operation.get()
  Future<Response> getAll() async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final sql = 'SELECT id, text, date_time, photo, user_id, recipe_id FROM _comment';
      final result = await store.execute(sql) as List<List<dynamic>>;
      
      final comments = result.map((row) => rowToMap(row)).toList();
      return Response.ok(comments);
    } catch (e) {
      print("Error fetching comments: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @override
  String get tableName => '_comment';
  
  @override
  List<String> get columns => ['id', 'text', 'date_time', 'photo', 'user_id', 'recipe_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'text': row[1],
      'dateTime': row[2]?.toIso8601String(),
      'photo': row[3],
      'user': row[4] != null ? {'id': row[4]} : null,
      'recipe': row[5] != null ? {'id': row[5]} : null
    };
  }
  
  @override
  @Operation.post()
  Future<Response> create() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("POST /comment - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{};
      
      // Required fields
      if (body['text'] == null) {
        return Response.badRequest(body: {"error": "text is required"});
      }
      
      values['text'] = body['text'];
      values['date_time'] = body['dateTime'] ?? body['datetime'] ?? DateTime.now().toIso8601String();
      
      // Optional fields
      if (body.containsKey('photo')) {
        values['photo'] = body['photo'];
      }
      
      // Relations
      if (body.containsKey('user') && body['user'] != null) {
        if (body['user'] is Map && body['user']['id'] != null) {
          values['user_id'] = body['user']['id'];
        }
      }
      
      if (body.containsKey('recipe') && body['recipe'] != null) {
        if (body['recipe'] is Map && body['recipe']['id'] != null) {
          values['recipe_id'] = body['recipe']['id'];
        }
      }
      
      final columns = ['text', 'date_time'];
      final valueNames = ['@text', '@date_time'];
      
      if (values.containsKey('photo')) {
        columns.add('photo');
        valueNames.add('@photo');
      }
      if (values.containsKey('user_id')) {
        columns.add('user_id');
        valueNames.add('@user_id');
      }
      if (values.containsKey('recipe_id')) {
        columns.add('recipe_id');
        valueNames.add('@recipe_id');
      }
      
      final sql = "INSERT INTO _comment (${columns.join(', ')}) VALUES (${valueNames.join(', ')}) RETURNING id, text, date_time, photo, user_id, recipe_id";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to insert comment"});
    } catch (e) {
      print("Error inserting comment: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}


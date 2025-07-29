import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/favorite.dart';
import 'base_controller.dart';

class FavoriteController extends BaseController<Favorite> {
  FavoriteController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_favorite';
  
  @override
  List<String> get columns => ['id', 'recipe_id', 'user_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'recipe': row[1] != null ? {'id': row[1]} : null,
      'user': row[2] != null ? {'id': row[2]} : null
    };
  }
  
  @override
  @Operation.post()
  Future<Response> create() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("POST /favorite - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{};
      
      // Relations
      if (body.containsKey('recipe') && body['recipe'] != null) {
        if (body['recipe'] is Map && body['recipe']['id'] != null) {
          values['recipe_id'] = body['recipe']['id'];
        }
      }
      
      if (body.containsKey('user') && body['user'] != null) {
        if (body['user'] is Map && body['user']['id'] != null) {
          values['user_id'] = body['user']['id'];
        }
      }
      
      if (!values.containsKey('recipe_id') || !values.containsKey('user_id')) {
        return Response.badRequest(body: {"error": "recipe and user are required"});
      }
      
      final sql = "INSERT INTO _favorite (recipe_id, user_id) VALUES (@recipe_id, @user_id) RETURNING id, recipe_id, user_id";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to insert favorite"});
    } catch (e) {
      print("Error inserting favorite: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}


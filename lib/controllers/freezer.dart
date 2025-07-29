import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/freezer.dart';
import 'base_controller.dart';

class FreezerController extends BaseController<Freezer> {
  FreezerController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_freezer';
  
  @override
  List<String> get columns => ['id', 'count', 'user_id', 'ingredient_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'count': row[1],
      'user': row[2] != null ? {'id': row[2]} : null,
      'ingredient': row[3] != null ? {'id': row[3]} : null
    };
  }
  
  @override
  @Operation.post()
  Future<Response> create() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("POST /freezer - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{};
      
      // Required fields
      if (body['count'] == null) {
        return Response.badRequest(body: {"error": "count is required"});
      }
      
      values['count'] = body['count'];
      
      // Relations
      if (body.containsKey('user') && body['user'] != null) {
        if (body['user'] is Map && body['user']['id'] != null) {
          values['user_id'] = body['user']['id'];
        }
      }
      
      if (body.containsKey('ingredient') && body['ingredient'] != null) {
        if (body['ingredient'] is Map && body['ingredient']['id'] != null) {
          values['ingredient_id'] = body['ingredient']['id'];
        }
      }
      
      final columns = ['count'];
      final valueNames = ['@count'];
      
      if (values.containsKey('user_id')) {
        columns.add('user_id');
        valueNames.add('@user_id');
      }
      if (values.containsKey('ingredient_id')) {
        columns.add('ingredient_id');
        valueNames.add('@ingredient_id');
      }
      
      final sql = "INSERT INTO _freezer (${columns.join(', ')}) VALUES (${valueNames.join(', ')}) RETURNING id, count, user_id, ingredient_id";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to insert freezer"});
    } catch (e) {
      print("Error inserting freezer: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}

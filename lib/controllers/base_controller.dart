import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

abstract class BaseController<T extends ManagedObject> extends ResourceController {
  BaseController(this.context);
  
  final ManagedContext context;
  
  String get tableName;
  List<String> get columns;
  Map<String, dynamic> rowToMap(List<dynamic> row);
  
  @Operation.post()
  Future<Response> create() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("POST /$tableName - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final columnNames = <String>[];
      final valueNames = <String>[];
      final values = <String, dynamic>{};
      
      body.forEach((key, value) {
        if (columns.contains(key) && key != 'id') {
          columnNames.add(key);
          valueNames.add('@$key');
          values[key] = value;
        }
      });
      
      if (columnNames.isEmpty) {
        return Response.badRequest(body: {"error": "No valid fields provided"});
      }
      
      final sql = "INSERT INTO $tableName (${columnNames.join(', ')}) VALUES (${valueNames.join(', ')}) RETURNING ${columns.join(', ')}";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to insert"});
    } catch (e) {
      print("Error inserting: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.get()
  Future<Response> getAll() async {
    final query = Query<T>(context);
    final items = await query.fetch();
    return Response.ok(items);
  }
  
  @Operation.get('id')
  Future<Response> getByID(@Bind.path('id') int id) async {
    final query = Query<T>(context)
      ..where((dynamic o) => o.id).equalTo(id);
    
    final item = await query.fetchOne();
    
    if (item == null) {
      return Response.notFound();
    }
    
    return Response.ok(item);
  }
  
  @Operation.put('id')
  Future<Response> update(@Bind.path('id') int id) async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("PUT /$tableName/$id - Received body: $body");
    
    try {
      // Check if exists
      final checkQuery = Query<T>(context)
        ..where((dynamic o) => o.id).equalTo(id);
      final existing = await checkQuery.fetchOne();
      
      if (existing == null) {
        return Response.notFound();
      }
      
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final updates = <String>[];
      final values = <String, dynamic>{'id': id};
      
      body.forEach((key, value) {
        if (columns.contains(key) && key != 'id') {
          updates.add('$key = @$key');
          values[key] = value;
        }
      });
      
      if (updates.isEmpty) {
        return Response.badRequest(body: {"error": "No fields to update"});
      }
      
      final sql = "UPDATE $tableName SET ${updates.join(', ')} WHERE id = @id RETURNING ${columns.join(', ')}";
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to update"});
    } catch (e) {
      print("Error updating: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @Operation.delete('id')
  Future<Response> delete(@Bind.path('id') int id) async {
    try {
      final query = Query<T>(context)
        ..where((dynamic o) => o.id).equalTo(id);
      
      final deletedCount = await query.delete();
      
      if (deletedCount == 0) {
        return Response.notFound();
      }
      
      return Response.ok({"message": "Deleted successfully"});
    } catch (e) {
      print("Error deleting: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}
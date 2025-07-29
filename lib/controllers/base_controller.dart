import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

abstract class BaseController<T extends ManagedObject> extends ResourceController {
  BaseController(this.context);
  
  final ManagedContext context;
  
  String get tableName;
  List<String> get columns;
  Map<String, dynamic> rowToMap(List<dynamic> row);
  
  // Метод для получения правильного имени колонки в SQL
  String getColumnName(String key) {
    // measureUnit_id все еще требует кавычек из-за camelCase
    const quotedColumns = ['measureUnit_id'];
    return quotedColumns.contains(key) ? '"$key"' : key;
  }
  
  // Метод для получения имени параметра (для substitutionValues)
  String getParamName(String key) {
    // Используем имя как есть, так как все в snake_case
    return key;
  }
  
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
          final paramName = getParamName(key);
          columnNames.add(getColumnName(key));
          valueNames.add('@$paramName');
          values[paramName] = value;
        }
      });
      
      if (columnNames.isEmpty) {
        return Response.badRequest(body: {"error": "No valid fields provided"});
      }
      
      final returningColumns = columns.map((col) => getColumnName(col)).join(', ');
      final sql = "INSERT INTO $tableName (${columnNames.join(', ')}) VALUES (${valueNames.join(', ')}) RETURNING $returningColumns";
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
          final paramName = getParamName(key);
          updates.add('${getColumnName(key)} = @$paramName');
          values[paramName] = value;
        }
      });
      
      if (updates.isEmpty) {
        return Response.badRequest(body: {"error": "No fields to update"});
      }
      
      final returningColumns = columns.map((col) => getColumnName(col)).join(', ');
      final sql = "UPDATE $tableName SET ${updates.join(', ')} WHERE id = @id RETURNING $returningColumns";
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
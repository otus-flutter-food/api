import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';

import '../model/ingredient.dart';
import 'base_controller.dart';

class MeasureUnitController extends BaseController<MeasureUnit> {
  MeasureUnitController(ManagedContext context) : super(context);
  
  @override
  String get tableName => '_measureunit';
  
  @override
  List<String> get columns => ['id', 'one', 'few', 'many'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'one': row[1],
      'few': row[2],
      'many': row[3]
    };
  }
}

class IngredientController extends BaseController<Ingredient> {
  IngredientController(ManagedContext context) : super(context);
  
  @override
  @Operation.get()
  Future<Response> getAll() async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final sql = 'SELECT id, name, calories_for_unit, "measureUnit_id" FROM _ingredient';
      final result = await store.execute(sql) as List<List<dynamic>>;
      
      final ingredients = result.map((row) => rowToMap(row)).toList();
      return Response.ok(ingredients);
    } catch (e) {
      print("Error fetching ingredients: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @override
  @Operation.get('id')
  Future<Response> getByID(@Bind.path('id') int id) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final sql = 'SELECT id, name, calories_for_unit, "measureUnit_id" FROM _ingredient WHERE id = @id';
      final result = await store.execute(sql, substitutionValues: {'id': id}) as List<List<dynamic>>;
      
      if (result.isEmpty) {
        return Response.notFound();
      }
      
      return Response.ok(rowToMap(result.first));
    } catch (e) {
      print("Error fetching ingredient: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @override
  @Operation.put('id')
  Future<Response> update(@Bind.path('id') int id) async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("PUT /ingredient/$id - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      // Check if exists
      final checkSql = 'SELECT id FROM _ingredient WHERE id = @id';
      final checkResult = await store.execute(checkSql, substitutionValues: {'id': id}) as List<List<dynamic>>;
      
      if (checkResult.isEmpty) {
        return Response.notFound();
      }
      
      final updates = <String>[];
      final values = <String, dynamic>{'id': id};
      
      if (body.containsKey('name')) {
        updates.add('name = @name');
        values['name'] = body['name'];
      }
      if (body.containsKey('caloriesForUnit')) {
        updates.add('calories_for_unit = @calories_for_unit');
        values['calories_for_unit'] = body['caloriesForUnit'];
      }
      if (body.containsKey('measureUnit') && body['measureUnit'] != null) {
        if (body['measureUnit'] is Map && body['measureUnit']['id'] != null) {
          updates.add('"measureUnit_id" = @measureUnit_id');
          values['measureUnit_id'] = body['measureUnit']['id'];
        }
      }
      
      if (updates.isEmpty) {
        return Response.badRequest(body: {"error": "No fields to update"});
      }
      
      final sql = 'UPDATE _ingredient SET ${updates.join(', ')} WHERE id = @id RETURNING id, name, calories_for_unit, "measureUnit_id"';
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
  
  @override
  @Operation.delete('id')
  Future<Response> delete(@Bind.path('id') int id) async {
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final sql = 'DELETE FROM _ingredient WHERE id = @id';
      final result = await store.execute(sql, substitutionValues: {'id': id});
      
      final rowCount = result is int ? result : 0;
      
      if (rowCount == 0) {
        return Response.notFound();
      }
      
      return Response.ok({"message": "Deleted successfully"});
    } catch (e) {
      print("Error deleting: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
  
  @override
  String get tableName => '_ingredient';
  
  @override
  List<String> get columns => ['id', 'name', 'calories_for_unit', 'measureUnit_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'name': row[1],
      'caloriesForUnit': row[2],
      'measureUnit': row[3] != null ? {'id': row[3]} : null
    };
  }
  
  // Using BaseController's update method which handles camelCase properly
  
  @override
  @Operation.post()
  Future<Response> create() async {
    final body = await request!.body.decode<Map<String, dynamic>>();
    print("POST /ingredient - Received body: $body");
    
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{};
      
      // Required fields
      if (body['name'] == null || body['caloriesForUnit'] == null) {
        return Response.badRequest(body: {"error": "name and caloriesForUnit are required"});
      }
      
      values['name'] = body['name'];
      values['calories_for_unit'] = body['caloriesForUnit'];
      
      // Optional measureUnit
      if (body.containsKey('measureUnit') && body['measureUnit'] != null) {
        if (body['measureUnit'] is Map && body['measureUnit']['id'] != null) {
          values['measureUnit_id'] = body['measureUnit']['id'];
        }
      }
      
      final sql = values.containsKey('measureUnit_id')
          ? "INSERT INTO _ingredient (name, calories_for_unit, \"measureUnit_id\") VALUES (@name, @calories_for_unit, @measureUnit_id) RETURNING id, name, calories_for_unit, \"measureUnit_id\""
          : "INSERT INTO _ingredient (name, calories_for_unit) VALUES (@name, @calories_for_unit) RETURNING id, name, calories_for_unit, \"measureUnit_id\"";
      
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        return Response.ok(rowToMap(result.first));
      }
      
      return Response.serverError(body: {"error": "Failed to insert ingredient"});
    } catch (e) {
      print("Error inserting ingredient: $e");
      return Response.serverError(body: {"error": e.toString()});
    }
  }
}


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
  String get tableName => '_ingredient';
  
  @override
  List<String> get columns => ['id', 'name', 'caloriesForUnit', 'measureUnit_id'];
  
  @override
  Map<String, dynamic> rowToMap(List<dynamic> row) {
    return {
      'id': row[0],
      'name': row[1],
      'caloriesForUnit': row[2],
      'measureUnit': row[3] != null ? {'id': row[3]} : null
    };
  }
  
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
      values['caloriesForUnit'] = body['caloriesForUnit'];
      
      // Optional measureUnit
      if (body.containsKey('measureUnit') && body['measureUnit'] != null) {
        if (body['measureUnit'] is Map && body['measureUnit']['id'] != null) {
          values['measureUnit_id'] = body['measureUnit']['id'];
        }
      }
      
      final sql = values.containsKey('measureUnit_id')
          ? "INSERT INTO _ingredient (name, \"caloriesForUnit\", \"measureUnit_id\") VALUES (@name, @caloriesForUnit, @measureUnit_id) RETURNING id, name, \"caloriesForUnit\", \"measureUnit_id\""
          : "INSERT INTO _ingredient (name, \"caloriesForUnit\") VALUES (@name, @caloriesForUnit) RETURNING id, name, \"caloriesForUnit\", \"measureUnit_id\"";
      
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


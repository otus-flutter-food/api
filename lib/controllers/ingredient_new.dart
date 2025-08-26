import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import '../model/ingredient.dart';
import '../model/freezer.dart';
import '../middleware/naming_middleware.dart';
import '../utils/naming_converter.dart';

class IngredientController extends NamingController {
  IngredientController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список ингредиентов", context.schema['Ingredient']),
        "404": APIResponse("Ингредиент не найден")
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Ингредиент создан", context.schema['Ingredient']),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "PUT") {
      return {
        "200": APIResponse.schema("Ингредиент обновлён", context.schema['Ingredient']),
        "404": APIResponse("Ингредиент не найден"),
        "400": APIResponse("Ошибка валидации данных")
      };
    } else if (operation.method == "DELETE") {
      return {
        "200": APIResponse("Ингредиент успешно удалён"),
        "404": APIResponse("Ингредиент не найден"),
        "409": APIResponse("Нельзя удалить ингредиент, используемый в рецептах")
      };
    }
    return {};
  }
  
  @Operation.get()
  Future<Response> getAllIngredients() async {
    final query = Query<Ingredient>(context)
      ..join(object: (i) => i.measureunit);
    
    final ingredients = await query.fetch();
    
    return createResponseWithNamingConversion(200, ingredients.map((i) => i.asMap()).toList());
  }
  
  @Operation.get('id')
  Future<Response> getIngredientByID(@Bind.path('id') int id) async {
    final query = Query<Ingredient>(context)
      ..where((i) => i.id).equalTo(id)
      ..join(object: (i) => i.measureunit);
    
    final ingredient = await query.fetchOne();
    
    if (ingredient == null) {
      return createResponseWithNamingConversion(404, {'error': 'Ingredient not found'});
    }
    
    return createResponseWithNamingConversion(200, ingredient.asMap());
  }
  
  @Operation.post()
  Future<Response> createIngredient() async {
    try {
      // Декодируем с поддержкой camelCase конвертации
      final body = await decodeBodyWithNamingConversion();
      
      print("Creating ingredient with body: $body");
      
      if (body['name'] == null || body['calories_for_unit'] == null) {
        return createResponseWithNamingConversion(400, {"error": "name and caloriesForUnit are required"});
      }
      
      // Используем прямой SQL для вставки из-за проблем с типами в Conduit ORM
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final values = <String, dynamic>{
        'name': body['name'],
        'calories_for_unit': body['calories_for_unit']?.toDouble(),
      };
      
      String sql;
      
      // Если указан measureUnit, добавим его
      if (body['measureunit'] != null && body['measureunit']['id'] != null) {
        final measureUnitId = int.tryParse(body['measureunit']['id'].toString());
        if (measureUnitId == null) {
          return createResponseWithNamingConversion(400, {'error': 'Invalid measureUnit ID format'});
        }
        
        // Проверим, что measureUnit существует
        final checkSql = 'SELECT id FROM _measureunit WHERE id = @measureunit_id';
        final checkResult = await store.execute(checkSql, substitutionValues: {'measureunit_id': measureUnitId});
        
        if (checkResult.isEmpty) {
          return createResponseWithNamingConversion(400, {'error': 'Invalid measureUnit ID'});
        }
        
        values['measureunit_id'] = measureUnitId;
        sql = "INSERT INTO _ingredient (name, calories_for_unit, measureunit_id) VALUES (@name, @calories_for_unit, @measureunit_id) RETURNING id, name, calories_for_unit, measureunit_id";
      } else {
        sql = "INSERT INTO _ingredient (name, calories_for_unit) VALUES (@name, @calories_for_unit) RETURNING id, name, calories_for_unit, measureunit_id";
      }
      
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        final row = result.first;
        final responseData = <String, dynamic>{
          'id': row[0],
          'name': row[1],
          'caloriesForUnit': row[2],
          'measureunit': row[3] != null ? {'id': row[3]} : null
        };
        
        // Если есть measureUnit, получим полную информацию
        if (row[3] != null) {
          final measureUnitSql = 'SELECT id, one, few, many FROM _measureunit WHERE id = @id';
          final measureUnitResult = await store.execute(measureUnitSql, substitutionValues: {'id': row[3]}) as List<List<dynamic>>;
          
          if (measureUnitResult.isNotEmpty) {
            final muRow = measureUnitResult.first;
            responseData['measureunit'] = {
              'id': muRow[0],
              'one': muRow[1],
              'few': muRow[2],
              'many': muRow[3]
            };
          }
        }
        
        return createResponseWithNamingConversion(200, responseData);
      }
      
      return createResponseWithNamingConversion(500, {"error": "Failed to insert ingredient"});
    } catch (e) {
      print("Error creating ingredient: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }
  
  @Operation.put('id')
  Future<Response> updateIngredient(@Bind.path('id') int id) async {
    try {
      // Декодируем с поддержкой camelCase конвертации
      final body = await decodeBodyWithNamingConversion();
      
      // Используем прямой SQL из-за проблем с типами в Conduit ORM
      final store = context.persistentStore as PostgreSQLPersistentStore;
      
      // Проверяем существование ингредиента
      final checkSql = 'SELECT id FROM _ingredient WHERE id = @id';
      final checkResult = await store.execute(checkSql, substitutionValues: {'id': id}) as List<List<dynamic>>;
      
      if (checkResult.isEmpty) {
        return createResponseWithNamingConversion(404, {'error': 'Ingredient not found'});
      }
      
      final updates = <String>[];
      final values = <String, dynamic>{'id': id};
      
      if (body.containsKey('name')) {
        updates.add('name = @name');
        values['name'] = body['name'];
      }
      if (body.containsKey('calories_for_unit')) {
        updates.add('calories_for_unit = @calories_for_unit');
        values['calories_for_unit'] = body['calories_for_unit'];
      }
      if (body.containsKey('measureunit') && body['measureunit'] != null) {
        if (body['measureunit'] is Map && body['measureunit']['id'] != null) {
          final measureUnitId = int.tryParse(body['measureunit']['id'].toString());
          if (measureUnitId == null) {
            return createResponseWithNamingConversion(400, {'error': 'Invalid measureUnit ID format'});
          }
          
          updates.add('measureunit_id = @measureunit_id');
          values['measureunit_id'] = measureUnitId;
        }
      }
      
      if (updates.isEmpty) {
        return createResponseWithNamingConversion(400, {"error": "No fields to update"});
      }
      
      final sql = 'UPDATE _ingredient SET ${updates.join(', ')} WHERE id = @id RETURNING id, name, calories_for_unit, measureunit_id';
      final result = await store.execute(sql, substitutionValues: values) as List<List<dynamic>>;
      
      if (result.isNotEmpty) {
        final row = result.first;
        final responseData = <String, dynamic>{
          'id': row[0],
          'name': row[1],
          'caloriesForUnit': row[2],
          'measureunit': row[3] != null ? {'id': row[3]} : null
        };
        
        // Если есть measureUnit, получим полную информацию
        if (row[3] != null) {
          final measureUnitSql = 'SELECT id, one, few, many FROM _measureunit WHERE id = @id';
          final measureUnitResult = await store.execute(measureUnitSql, substitutionValues: {'id': row[3]}) as List<List<dynamic>>;
          
          if (measureUnitResult.isNotEmpty) {
            final muRow = measureUnitResult.first;
            responseData['measureunit'] = {
              'id': muRow[0],
              'one': muRow[1],
              'few': muRow[2],
              'many': muRow[3]
            };
          }
        }
        
        return createResponseWithNamingConversion(200, responseData);
      }
      
      return createResponseWithNamingConversion(500, {"error": "Failed to update"});
    } catch (e) {
      print("Error updating ingredient: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }
  
  @Operation.delete('id')
  Future<Response> deleteIngredient(@Bind.path('id') int id) async {
    try {
      // Проверяем существование ингредиента
      final ingredientQuery = Query<Ingredient>(context)
        ..where((i) => i.id).equalTo(id);
      final ingredient = await ingredientQuery.fetchOne();
      
      if (ingredient == null) {
        return createResponseWithNamingConversion(404, {'error': 'Ingredient not found'});
      }
      
      // Проверяем использование в рецептах через ORM
      final recipeCheckQuery = Query<RecipeIngredient>(context)
        ..where((ri) => ri.ingredient!.id).equalTo(id);
      final recipeIngredients = await recipeCheckQuery.fetch();
      
      if (recipeIngredients.isNotEmpty) {
        return createResponseWithNamingConversion(409, {
          'error': 'Cannot delete ingredient that is used in recipes',
          'count': recipeIngredients.length
        });
      }
      
      // Проверяем использование в морозилке через ORM
      final freezerCheckQuery = Query<Freezer>(context)
        ..where((f) => f.ingredient!.id).equalTo(id);
      final freezerItems = await freezerCheckQuery.fetch();
      
      if (freezerItems.isNotEmpty) {
        return createResponseWithNamingConversion(409, {
          'error': 'Cannot delete ingredient that is in freezer',
          'count': freezerItems.length
        });
      }
      
      // Удаляем ингредиент через ORM
      final deleteQuery = Query<Ingredient>(context)
        ..where((i) => i.id).equalTo(id);
      final deletedCount = await deleteQuery.delete();
      
      if (deletedCount == 0) {
        return createResponseWithNamingConversion(404, {'error': 'Ingredient not found'});
      }
      
      return createResponseWithNamingConversion(200, {'message': 'Ingredient deleted successfully', 'id': id});
    } catch (e) {
      print("Error deleting ingredient: $e");
      return createResponseWithNamingConversion(500, {"error": e.toString()});
    }
  }
}
import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/src/v3/schema.dart';
import '../model/ingredient.dart';

class MeasureUnitController extends ResourceController {
  MeasureUnitController(this.context);
  
  final ManagedContext context;
  
  @override
  Map<String, APIResponse> documentOperationResponses(
    context, 
    Operation operation
  ) {
    if (operation.method == "GET") {
      return {
        "200": APIResponse.schema("Список единиц измерения", context.schema['MeasureUnit'])
      };
    } else if (operation.method == "POST") {
      return {
        "200": APIResponse.schema("Единица измерения создана", context.schema['MeasureUnit'])
      };
    }
    return {};
  }
  
  
  @Operation.get()
  Future<Response> getAllUnits() async {
    final query = Query<MeasureUnit>(context);
    final units = await query.fetch();
    
    return Response.ok(units.map((u) => u.asMap()).toList());
  }
  
  @Operation.get('id')
  Future<Response> getUnitByID(@Bind.path('id') int id) async {
    final query = Query<MeasureUnit>(context)
      ..where((u) => u.id).equalTo(id);
    
    final unit = await query.fetchOne();
    
    if (unit == null) {
      return Response.notFound(body: {'error': 'MeasureUnit not found'});
    }
    
    return Response.ok(unit.asMap());
  }
  
  @Operation.post()
  Future<Response> createUnit(@Bind.body() MeasureUnit unit) async {
    final query = Query<MeasureUnit>(context)
      ..values = unit;
    
    final insertedUnit = await query.insert();
    return Response.ok(insertedUnit.asMap());
  }
  
  @Operation.put('id')
  Future<Response> updateUnit(
    @Bind.path('id') int id,
    @Bind.body() MeasureUnit updatedUnit,
  ) async {
    final query = Query<MeasureUnit>(context)
      ..where((u) => u.id).equalTo(id)
      ..values = updatedUnit;
    
    final unit = await query.updateOne();
    
    if (unit == null) {
      return Response.notFound(body: {'error': 'MeasureUnit not found'});
    }
    
    return Response.ok(unit.asMap());
  }
  
  @Operation.delete('id')
  Future<Response> deleteUnit(@Bind.path('id') int id) async {
    // Check if used by any ingredients
    final checkQuery = Query<Ingredient>(context)
      ..where((i) => i.measureunit!.id).equalTo(id);
    
    final usedCount = await checkQuery.reduce.count();
    
    if (usedCount > 0) {
      return Response.conflict(body: {
        'error': 'Cannot delete MeasureUnit that is used by ingredients',
        'count': usedCount
      });
    }
    
    final query = Query<MeasureUnit>(context)
      ..where((u) => u.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'MeasureUnit not found'});
    }
    
    return Response.ok({'message': 'MeasureUnit deleted successfully', 'id': id});
  }
}
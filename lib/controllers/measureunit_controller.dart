import 'package:conduit_core/conduit_core.dart';
import 'package:conduit_open_api/src/v3/response.dart';
import 'package:conduit_open_api/src/v3/schema.dart';
import 'package:conduit_postgresql/conduit_postgresql.dart';
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
        "200": APIResponse.schema("Список единиц измерения", APISchemaObject.array(ofSchema: context.schema['MeasureUnit']))
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
  Future<Response> createUnit() async {
    final Map<String, dynamic> body = await request!.body.decode();
    final one = body['one']?.toString();
    final few = body['few']?.toString();
    final many = body['many']?.toString();
    if (one == null || few == null || many == null) {
      return Response.badRequest(body: {'error': 'one, few, many are required'});
    }
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      final rows = await store.execute(
        'INSERT INTO _measureunit (one, few, many) VALUES (@one, @few, @many) '
        'RETURNING id, one, few, many',
        substitutionValues: {'one': one, 'few': few, 'many': many},
      ) as List<List<dynamic>>;
      if (rows.isEmpty) return Response.serverError(body: {'error': 'Insert failed'});
      final r = rows.first;
      return Response.ok({'id': r[0], 'one': r[1], 'few': r[2], 'many': r[3]});
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
  }
  
  @Operation.put('id')
  Future<Response> updateUnit(
    @Bind.path('id') int id,
  ) async {
    final Map<String, dynamic> body = await request!.body.decode();
    final updates = <String>[];
    final values = <String, dynamic>{'id': id};
    if (body.containsKey('one')) { updates.add('one = @one'); values['one'] = body['one'].toString(); }
    if (body.containsKey('few')) { updates.add('few = @few'); values['few'] = body['few'].toString(); }
    if (body.containsKey('many')) { updates.add('many = @many'); values['many'] = body['many'].toString(); }
    if (updates.isEmpty) return Response.badRequest(body: {'error': 'No fields to update'});
    try {
      final store = context.persistentStore as PostgreSQLPersistentStore;
      await store.execute('UPDATE _measureunit SET ${updates.join(', ')} WHERE id = @id', substitutionValues: values);
      final res = await store.execute('SELECT id, one, few, many FROM _measureunit WHERE id = @id', substitutionValues: {'id': id}) as List<List<dynamic>>;
      if (res.isEmpty) return Response.notFound(body: {'error': 'MeasureUnit not found'});
      final r = res.first;
      return Response.ok({'id': r[0], 'one': r[1], 'few': r[2], 'many': r[3]});
    } catch (e) {
      return Response.badRequest(body: {'error': e.toString()});
    }
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

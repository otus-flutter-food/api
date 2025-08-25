import 'package:conduit_core/conduit_core.dart';
import '../model/freezer.dart';
import '../model/user.dart';
import '../model/ingredient.dart';

class FreezerController extends ResourceController {
  FreezerController(this.context);
  
  final ManagedContext context;
  
  @Operation.get()
  Future<Response> getAllFreezerItems() async {
    final query = Query<Freezer>(context);
    
    final items = await query.fetch();
    
    // Manually populate relations if needed
    final results = [];
    for (var item in items) {
      final map = item.asMap();
      
      // Add user info if needed
      if (item.user?.id != null) {
        final userQuery = Query<User>(context)
          ..where((u) => u.id).equalTo(item.user!.id!);
        final user = await userQuery.fetchOne();
        if (user != null) {
          map['user'] = {'id': user.id, 'login': user.login};
        }
      }
      
      // Add ingredient info if needed
      if (item.ingredient?.id != null) {
        // Just add the ID for now to avoid column name issues
        map['ingredient'] = {'id': item.ingredient!.id};
      }
      
      results.add(map);
    }
    
    return Response.ok(results);
  }
  
  @Operation.get('id')
  Future<Response> getFreezerItemByID(@Bind.path('id') int id) async {
    final query = Query<Freezer>(context)
      ..where((f) => f.id).equalTo(id);
    
    final item = await query.fetchOne();
    
    if (item == null) {
      return Response.notFound(body: {'error': 'Freezer item not found'});
    }
    
    final map = item.asMap();
    
    // Add user info if needed
    if (item.user?.id != null) {
      final userQuery = Query<User>(context)
        ..where((u) => u.id).equalTo(item.user!.id!);
      final user = await userQuery.fetchOne();
      if (user != null) {
        map['user'] = {'id': user.id, 'login': user.login};
      }
    }
    
    // Add ingredient info if needed  
    if (item.ingredient?.id != null) {
      map['ingredient'] = {'id': item.ingredient!.id};
    }
    
    return Response.ok(map);
  }
  
  @Operation.post()
  Future<Response> createFreezerItem(@Bind.body() Freezer freezerItem) async {
    // Validate user exists
    if (freezerItem.user?.id != null) {
      final userQuery = Query<User>(context)
        ..where((u) => u.id).equalTo(freezerItem.user!.id!);
      
      final user = await userQuery.fetchOne();
      if (user == null) {
        return Response.badRequest(body: {'error': 'Invalid user ID'});
      }
    }
    
    // Validate ingredient exists
    if (freezerItem.ingredient?.id != null) {
      // Use a simple count check to avoid join issues
      final ingredientQuery = Query<Ingredient>(context)
        ..where((i) => i.id).equalTo(freezerItem.ingredient!.id!);
      
      final count = await ingredientQuery.reduce.count();
      if (count == 0) {
        return Response.badRequest(body: {'error': 'Invalid ingredient ID'});
      }
    }
    
    // Check if already exists
    final existingQuery = Query<Freezer>(context)
      ..where((f) => f.user!.id).equalTo(freezerItem.user!.id!)
      ..where((f) => f.ingredient!.id).equalTo(freezerItem.ingredient!.id!);
    
    final existing = await existingQuery.fetchOne();
    if (existing != null) {
      // Update count instead
      existing.count = (existing.count ?? 0) + (freezerItem.count ?? 0);
      final updateQuery = Query<Freezer>(context)
        ..where((f) => f.id).equalTo(existing.id!)
        ..values.count = existing.count;
      
      final updated = await updateQuery.updateOne();
      return Response.ok(updated?.asMap());
    }
    
    // Create new item
    final query = Query<Freezer>(context)
      ..values = freezerItem;
    
    final insertedItem = await query.insert();
    
    // Return simple result without joins to avoid column name issues
    return Response.ok(insertedItem.asMap());
  }
  
  @Operation.put('id')
  Future<Response> updateFreezerItem(
    @Bind.path('id') int id,
    @Bind.body() Freezer updatedItem,
  ) async {
    final query = Query<Freezer>(context)
      ..where((f) => f.id).equalTo(id)
      ..values = updatedItem;
    
    final item = await query.updateOne();
    
    if (item == null) {
      return Response.notFound(body: {'error': 'Freezer item not found'});
    }
    
    // Return simple result without joins to avoid column name issues
    return Response.ok(item.asMap());
  }
  
  @Operation.delete('id')
  Future<Response> deleteFreezerItem(@Bind.path('id') int id) async {
    final query = Query<Freezer>(context)
      ..where((f) => f.id).equalTo(id);
    
    final deletedCount = await query.delete();
    
    if (deletedCount == 0) {
      return Response.notFound(body: {'error': 'Freezer item not found'});
    }
    
    return Response.ok({'message': 'Freezer item deleted successfully', 'id': id});
  }
  
  // Additional endpoints for user-specific freezer
  @Operation.get('user', 'userId')
  Future<Response> getUserFreezer(@Bind.path('userId') int userId) async {
    final query = Query<Freezer>(context)
      ..where((f) => f.user!.id).equalTo(userId);
    
    final items = await query.fetch();
    
    // Add ingredient info without joins
    final results = [];
    for (var item in items) {
      final map = item.asMap();
      if (item.ingredient?.id != null) {
        map['ingredient'] = {'id': item.ingredient!.id};
      }
      results.add(map);
    }
    
    return Response.ok(results);
  }
}
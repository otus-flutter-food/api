import 'dart:async';
import 'package:conduit_core/conduit_core.dart';


class Migration5 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Comment", SchemaColumn("date_time", ManagedPropertyType.datetime, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.deleteColumn("_Comment", "datetime");
		database.addColumn("_Ingredient", SchemaColumn("calories_for_unit", ManagedPropertyType.doublePrecision, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.deleteColumn("_Ingredient", "caloriesForUnit");
		database.alterColumn("_Recipe", "name", (c) {c.isNullable = false;});
		database.alterColumn("_Recipe", "duration", (c) {c.isNullable = false;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    
import 'dart:async';
import 'package:conduit/conduit.dart';   

class Migration2 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Comment", SchemaColumn.relationship("recipe", ManagedPropertyType.bigInteger, relatedTableName: "_Recipe", relatedColumnName: "id", rule: DeleteRule.nullify, isNullable: true, isUnique: false));
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    
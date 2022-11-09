import 'dart:async';
import 'package:conduit/conduit.dart';   

class Migration3 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_User", SchemaColumn("username", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: true, isNullable: false, isUnique: true));
		database.addColumn("_User", SchemaColumn("email", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: true, isNullable: false, isUnique: true));
		database.addColumn("_User", SchemaColumn("accessToken", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.addColumn("_User", SchemaColumn("refreshToken", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.addColumn("_User", SchemaColumn("salt", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.addColumn("_User", SchemaColumn("hashPassword", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
		database.deleteColumn("_User", "login");
		database.deleteColumn("_User", "password");
		database.deleteColumn("_User", "token");
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    
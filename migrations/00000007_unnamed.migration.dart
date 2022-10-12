import 'dart:async';
import 'package:conduit/conduit.dart';

class Migration7 extends Migration {
  @override
  Future upgrade() async {
    database.addColumn("_User", SchemaColumn("token", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
    database.addColumn("_User", SchemaColumn("avatar", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false));
  }

  @override
  Future downgrade() async {}

  @override
  Future seed() async {}
}

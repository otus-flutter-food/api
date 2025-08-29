import 'dart:async';
import 'package:conduit_core/conduit_core.dart';

class Migration7 extends Migration {
  @override
  Future upgrade() async {
    final userTable = database.schemaTableForName('_User');
    final hasLogin = userTable?.columns.any((c) => c.name == 'login') ?? false;
    if (!hasLogin) {
      database.addColumn(
        "_User",
        SchemaColumn(
          "login",
          ManagedPropertyType.string,
          isPrimaryKey: false,
          autoincrement: false,
          isIndexed: false,
          isNullable: true,
          isUnique: false,
        ),
      );
    }
  }

  @override
  Future downgrade() async {
    // No-op (do not drop login column on downgrade)
  }

  @override
  Future seed() async {}
}


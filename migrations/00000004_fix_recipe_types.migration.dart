import 'dart:async';
import 'package:conduit_core/conduit_core.dart';

class Migration4 extends Migration {
  @override
  Future upgrade() async {
    // Убедимся, что типы колонок соответствуют ожиданиям Conduit
    database.alterColumn("_Recipe", "name", (c) {
      c.isNullable = true;
    });
    database.alterColumn("_Recipe", "duration", (c) {
      c.isNullable = true;
    });
  }

  @override
  Future downgrade() async {
    database.alterColumn("_Recipe", "name", (c) {
      c.isNullable = false;
    });
    database.alterColumn("_Recipe", "duration", (c) {
      c.isNullable = false;
    });
  }

  @override
  Future seed() async {}
}
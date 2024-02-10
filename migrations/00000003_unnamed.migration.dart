import 'dart:async';
import 'package:conduit_core/conduit_core.dart';

class Migration3 extends Migration {
  @override
  Future upgrade() async {
    database.alterColumn("_Comment", "photo", (c) {
      c.isNullable = true;
    });
  }

  @override
  Future downgrade() async {}

  @override
  Future seed() async {}
}

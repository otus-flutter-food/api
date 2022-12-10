import 'dart:async';
import 'package:conduit/conduit.dart';   

class Migration2 extends Migration { 
  @override
  Future upgrade() async {
   		database.alterColumn("_User", "token", (c) {c.isNullable = true;});
		database.alterColumn("_User", "avatar", (c) {c.isNullable = true;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    
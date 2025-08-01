import 'package:conduit_core/conduit_core.dart';

import 'recipe.dart';
import 'user.dart';

class Comment extends ManagedObject<_Comment> implements _Comment {}

class _Comment {
  @primaryKey
  int? id;

  @Relate(#comments)
  User? user;

  @Relate(#comments)
  Recipe? recipe;

  @Column()
  String? text;

  @Column(nullable: true)
  String? photo;

  @Column(name: "date_time")
  DateTime? dateTime;
}

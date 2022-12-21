import '../foodapi.dart';
import 'user.dart';
import 'recipe.dart';

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

  @Column()
  DateTime? datetime;
}

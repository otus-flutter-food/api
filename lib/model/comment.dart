import '../foodapi.dart';
import 'user.dart';

class Comment extends ManagedObject<_Comment> implements _Comment {}

class _Comment {
  @primaryKey
  int? id;

  @Relate(#comments)
  User? user;

  @Column()
  String? text;

  @Column()
  String? photo;

  @Column()
  DateTime? datetime;
}
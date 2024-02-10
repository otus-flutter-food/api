import 'package:conduit_core/conduit_core.dart';
import 'comment.dart';
import 'favorite.dart';
import 'freezer.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;

  @Column()
  String? login;

  @Column()
  String? password;

  @Column(nullable: true)
  String? token;

  @Column(nullable: true)
  String? avatar;

  ManagedSet<Freezer>? userFreezer;

  ManagedSet<Favorite>? favoriteRecipes;

  ManagedSet<Comment>? comments;
}
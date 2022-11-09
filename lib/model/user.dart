import '../foodapi.dart';
import 'comment.dart';
import 'favorite.dart';
import 'freezer.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;

  @Column(unique: true, indexed: true)
  String? username;

  @Serialize(input: true, output: false)
  String? password;

  @Column(unique: true, indexed: true)
  String? email;

  @Column(nullable: true)
  String? accessToken;

  @Column(nullable: true)
  String? refreshToken;

  @Column(omitByDefault: true)
  String? salt;

  @Column(omitByDefault: true)
  String? hashPassword;

  @Column()
  String? avatar;

  ManagedSet<Freezer>? userFreezer;

  ManagedSet<Favorite>? favoriteRecipes;

  ManagedSet<Comment>? comments;
}

import 'package:conduit_core/conduit_core.dart';
import 'comment.dart';
import 'favorite.dart';
import 'freezer.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;

  // Production schema fields
  @Column(name: 'first_name', nullable: true)
  String? firstName;

  @Column(name: 'last_name', nullable: true) 
  String? lastName;

  @Column(nullable: true)
  String? phone;

  @Column(name: 'avatar_url', nullable: true)
  String? avatarUrl;

  @Column(nullable: true)
  DateTime? birthday;

  @Column(nullable: true)
  String? token;

  // Keep for backward compatibility with existing code
  @Column(nullable: true)
  String? login;

  @Column(nullable: true)
  String? password;

  ManagedSet<Freezer>? userFreezer;

  ManagedSet<Favorite>? favoriteRecipes;

  ManagedSet<Comment>? comments;
}
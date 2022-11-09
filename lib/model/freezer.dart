import '../foodapi.dart';
import 'ingredient.dart';
import 'user.dart';

class Freezer extends ManagedObject<_Freezer> implements _Freezer {}

class _Freezer {
  @primaryKey
  int? id;

  @Relate(#userFreezer)
  User? user;

  @Relate(#ingredientFreezer)
  Ingredient? ingredient;

  @Column()
  double? count;
}
